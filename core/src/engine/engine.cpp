#include "engine.h"

#include "whisper.h"

#ifdef __ANDROID__
#include <android/log.h>
#endif

#include <algorithm>
#include <cstdio>
#include <thread>
#include <utility>
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

// Runs after whisper_full returns, when token level data is available.
void enrich_segments(whisper_context* ctx, SegmentList& segments,
                     bool word_timestamps, bool diarize)
{
    int speaker = 0;
    for (size_t i = 0; i < segments.size(); ++i) {
        const int index = static_cast<int>(i);
        if (diarize && i > 0 &&
            whisper_full_get_segment_speaker_turn_next(ctx, index - 1)) {
            ++speaker;
        }
        segments[i].speaker = speaker;
        if (!word_timestamps) continue;

        double sum = 0.0;
        int count = 0;
        const int tokens = whisper_full_n_tokens(ctx, index);
        for (int t = 0; t < tokens; ++t) {
            const char* text = whisper_full_get_token_text(ctx, index, t);
            if (text == nullptr || text[0] == '\0' || text[0] == '<') continue;
            const int64_t t0 = whisper_full_get_token_t0(ctx, index, t);
            const int64_t t1 = whisper_full_get_token_t1(ctx, index, t);
            if (t1 <= t0) continue;
            Word word;
            word.start_ms = t0 * 10;
            word.end_ms = t1 * 10;
            word.text = text;
            segments[i].words.push_back(std::move(word));
            sum += whisper_full_get_token_p(ctx, index, t);
            ++count;
        }
        segments[i].confidence = count > 0 ? static_cast<float>(sum / count) : 0.0f;
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
        // Flash attention lowers peak memory and is faster for long audio on
        // both CPU and GPU backends. whisper.cpp ignores it when unsupported.
        cparams.flash_attn = true;
        // Asked for token level alignment. whisper.cpp disables DTW when flash
        // attention is on, but still provides token timing for word cues.
        cparams.dtw_token_timestamps = true;

        whisper_context* ctx = whisper_init_from_file_with_params(options.model_path.c_str(), cparams);
        if (ctx == nullptr) {
            err = ErrorCode::ModelNotFound; // unreadable path or corrupt file both land here
            return nullptr;
        }

        auto engine = std::unique_ptr<Engine>(new Engine());
        engine->ctx_ = ctx;
#ifdef __ANDROID__
        // Route whisper.cpp diagnostics into the Android log. Whisper's own
        // log lines contain model metadata and progress, never the user's
        // audio or transcript.
        whisper_log_set([](enum ggml_log_level /*level*/, const char* text, void* /*user_data*/) {
            __android_log_print(ANDROID_LOG_INFO, "whisper", "%s", text);
        }, nullptr);
#endif
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
    // Refuse absurdly long inputs instead of building a multi-gigabyte PCM
    // buffer and getting killed by the OS. 16 kHz * 4 hours * 4 bytes.
    constexpr size_t kMaxSamples = size_t{16000} * 4 * 3600;
    if (n_samples > kMaxSamples) return ErrorCode::AudioTooLong;

    cancel_.store(false, std::memory_order_relaxed);
    progress_percent_.store(0, std::memory_order_relaxed);
    SegmentList collected;

    // whisper_full_default_params() fills every field with the OpenAI defaults.
    // We then override only what Kikoe needs. The abort callback is how we
    // implement cancellation: whisper.cpp checks it in its compute loop.
    const bool accurate = options.quality == 2;
    whisper_full_params wparams = whisper_full_default_params(
        accurate ? WHISPER_SAMPLING_BEAM_SEARCH : WHISPER_SAMPLING_GREEDY);
    if (accurate) wparams.beam_search.beam_size = 5;
    // Carry custom vocabulary into every decode window, not just the first.
    wparams.carry_initial_prompt = true;
    wparams.token_timestamps = options.word_timestamps;
    wparams.tdrz_enable = options.diarize;
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
        if (ccb) ccb->self->progress_percent_.store(progress, std::memory_order_relaxed);
        if (ccb && ccb->on_progress) ccb->on_progress(progress, ccb->user);
    };
    wparams.progress_callback_user_data = &cb;
    wparams.abort_callback = [](void* data) -> bool {
        auto* self = static_cast<Engine*>(data);
        return self->cancel_.load(std::memory_order_relaxed);
    };
    wparams.abort_callback_user_data = this;

    const int rc = whisper_full(ctx_, wparams, samples, static_cast<int>(n_samples));
    if (rc == 0) progress_percent_.store(100, std::memory_order_relaxed);
    if (rc != 0) {
        return cancel_.load(std::memory_order_relaxed) ? ErrorCode::Cancelled : ErrorCode::EngineFailed;
    }

    if (segments) {
        enrich_segments(ctx_, collected, options.word_timestamps, options.diarize);
        *segments = std::move(collected);
    }
    return ErrorCode::Ok;
}

} // namespace kikoe
