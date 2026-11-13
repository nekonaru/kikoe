#include "engine.h"

#include "whisper.h"

#include <algorithm>
#include <cstdio>
#include <thread>
#include <vector>

namespace kikoe {

namespace {

struct CallbackContext {
    Engine* self = nullptr;
    SegmentList* segments = nullptr;
    SegmentCallback on_segment = nullptr;
    ProgressCallback on_progress = nullptr;
    void* user = nullptr;
};

// whisper.cpp calls this from inside whisper_full() whenever at least one new
// segment has been decoded. `n_new` tells us how many segments to emit.
// Text and timestamps come from whisper_full_get_segment_*().
void on_new_segment(whisper_context* ctx, whisper_state* /*state*/, int n_new, void* user_data)
{
    auto* cb = static_cast<CallbackContext*>(user_data);
    if (cb == nullptr || cb->segments == nullptr) return;

    const int total = whisper_full_n_segments(ctx);
    const int from = std::max(0, total - n_new);
    for (int i = from; i < total; ++i) {
        Segment seg;
        // Whisper timestamps are in centiseconds; convert to milliseconds.
        seg.start_ms = whisper_full_get_segment_t0(ctx, i) * 10;
        seg.end_ms = whisper_full_get_segment_t1(ctx, i) * 10;
        const char* text = whisper_full_get_segment_text(ctx, i);
        seg.text = text ? text : "";
        // whisper.cpp prefixes segment text with a leading space; trim it.
        while (!seg.text.empty() && seg.text.front() == ' ') seg.text.erase(seg.text.begin());

        cb->segments->push_back(seg);
        if (cb->on_segment) cb->on_segment(seg, cb->user);
    }
}

} // namespace

std::unique_ptr<Engine> Engine::create(const EngineOptions& options, ErrorCode& err)
{
    err = ErrorCode::Ok;
    if (options.model_path.empty()) {
        err = ErrorCode::ModelNotFound;
        return nullptr;
    }

    try {
        whisper_context_params cparams = whisper_context_default_params();
        cparams.use_gpu = options.use_gpu;

        whisper_context* ctx = whisper_init_from_file_with_params(options.model_path.c_str(), cparams);
        if (ctx == nullptr) {
            err = ErrorCode::ModelNotFound; // unreadable path or corrupt file both land here
            return nullptr;
        }

        auto engine = std::unique_ptr<Engine>(new Engine());
        engine->ctx_ = ctx;
        if (options.n_threads > 0) {
            engine->n_threads_ = options.n_threads;
        } else {
            const unsigned hw = std::thread::hardware_concurrency();
            engine->n_threads_ = static_cast<int>(hw == 0 ? 1 : std::min(4u, hw));
        }
        return engine;
    } catch (...) {
        // No exception may cross the public boundary.
        err = ErrorCode::EngineFailed;
        return nullptr;
    }
}

Engine::~Engine()
{
    if (ctx_) whisper_free(ctx_);
}

void Engine::cancel()
{
    cancel_.store(true, std::memory_order_relaxed);
}

ErrorCode Engine::transcribe(const float* samples,
                             size_t n_samples,
                             const TranscribeOptions& options,
                             ProgressCallback on_progress,
                             SegmentCallback on_segment,
                             void* user,
                             SegmentList* segments)
{
    try {
        return transcribe_impl(samples, n_samples, options, on_progress, on_segment, user, segments);
    } catch (...) {
        return ErrorCode::EngineFailed;
    }
}

ErrorCode Engine::transcribe_impl(const float* samples,
                                  size_t n_samples,
                                  const TranscribeOptions& options,
                                  ProgressCallback on_progress,
                                  SegmentCallback on_segment,
                                  void* user,
                                  SegmentList* segments)
{
    if (samples == nullptr || n_samples == 0) return ErrorCode::InvalidArgument;
    if (ctx_ == nullptr) return ErrorCode::EngineFailed;

    cancel_.store(false, std::memory_order_relaxed);
    SegmentList collected;

    // whisper_full_default_params() fills every field with the OpenAI defaults.
    // We then override only what Kikoe needs. The abort callback is how we
    // implement cancellation: whisper.cpp checks it in its compute loop.
    whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    wparams.n_threads = n_threads_;
    wparams.translate = options.translate;
    wparams.language = options.language.empty() ? "auto" : options.language.c_str();
    wparams.initial_prompt = options.initial_prompt.empty() ? nullptr : options.initial_prompt.c_str();
    wparams.no_speech_thold = options.no_speech_threshold;
    wparams.print_progress = false;
    wparams.print_special = false;
    wparams.print_realtime = false;
    wparams.print_timestamps = false;
    if (options.vad) {
        wparams.vad = true;
        wparams.vad_model_path = options.vad_model_path.c_str();
    }

    CallbackContext cb;
    cb.self = this;
    cb.segments = &collected;
    cb.on_segment = on_segment;
    cb.on_progress = on_progress;
    cb.user = user;

    wparams.new_segment_callback = on_new_segment;
    wparams.new_segment_callback_user_data = &cb;
    wparams.progress_callback = [](whisper_context* /*ctx*/, whisper_state* /*state*/, int progress, void* user_data) {
        auto* ccb = static_cast<CallbackContext*>(user_data);
        if (ccb && ccb->on_progress) ccb->on_progress(progress, ccb->user);
    };
    wparams.progress_callback_user_data = &cb;
    wparams.abort_callback = [](void* data) -> bool {
        auto* self = static_cast<Engine*>(data);
        return self->cancel_.load(std::memory_order_relaxed);
    };
    wparams.abort_callback_user_data = this;

    const int rc = whisper_full(ctx_, wparams, samples, static_cast<int>(n_samples));
    if (rc != 0) {
        return cancel_.load(std::memory_order_relaxed) ? ErrorCode::Cancelled : ErrorCode::EngineFailed;
    }

    if (segments) *segments = std::move(collected);
    return ErrorCode::Ok;
}

} // namespace kikoe
