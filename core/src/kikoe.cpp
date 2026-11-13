/*
 * Kikoe C API implementation.
 *
 * This file is the boundary between the C API (stable, FFI-safe) and the C++
 * engine. Rules for this file:
 *  - no exception crosses into C;
 *  - every function validates its arguments;
 *  - memory returned to callers is owned here and documented in kikoe.h;
 *  - the error codes map 1:1 with enum kk_error.
 */
#include "kikoe.h"

#include "../src/audio/media_pcm.h"
#include "../src/engine/engine.h"
#include "../src/error.h"
#include "../src/format/formatter.h"
#include "../src/model/model_manager.h"
#include "../src/model/model_registry.h"

#include <cstring>
#include <memory>
#include <new>
#include <string>
#include <utility>
#include <vector>

struct kk_engine {
    kikoe::EngineOptions engine_options;
    std::unique_ptr<kikoe::Engine> engine;
    kikoe::SegmentList last_segments;
    bool vad = false;
    std::string vad_model_path;
};

namespace {

int to_kk_error(kikoe::ErrorCode code)
{
    // Values deliberately match enum kk_error.
    return static_cast<int>(code);
}

// Map a kk_options pointer to TranscribeOptions. NULL options = defaults.
kikoe::TranscribeOptions to_transcribe_options(const kk_options* o)
{
    kikoe::TranscribeOptions out;
    if (o) {
        if (o->language && o->language[0] != '\0') out.language = o->language;
        out.translate = o->translate != 0;
        if (o->initial_prompt) out.initial_prompt = o->initial_prompt;
    }
    return out;
}

} // namespace

int kk_abi_version(void)
{
    return KK_ABI_VERSION_MAJOR * 100 + KK_ABI_VERSION_MINOR;
}

const char* kk_version_string(void)
{
    return "0.1.0";
}

const char* kk_error_string(int err)
{
    switch (err) {
    case KK_OK:                    return "ok";
    case KK_ERR_IO:                return kikoe::error_string(kikoe::ErrorCode::Io);
    case KK_ERR_INVALID_MEDIA:     return kikoe::error_string(kikoe::ErrorCode::InvalidMedia);
    case KK_ERR_UNSUPPORTED_FORMAT: return kikoe::error_string(kikoe::ErrorCode::UnsupportedFormat);
    case KK_ERR_DECODER_FAILED:    return kikoe::error_string(kikoe::ErrorCode::DecoderFailed);
    case KK_ERR_DECODER_NOT_FOUND: return kikoe::error_string(kikoe::ErrorCode::DecoderNotFound);
    case KK_ERR_MODEL_NOT_FOUND:   return kikoe::error_string(kikoe::ErrorCode::ModelNotFound);
    case KK_ERR_MODEL_CHECKSUM:    return kikoe::error_string(kikoe::ErrorCode::ModelChecksum);
    case KK_ERR_CANCELLED:         return kikoe::error_string(kikoe::ErrorCode::Cancelled);
    case KK_ERR_OUT_OF_MEMORY:     return kikoe::error_string(kikoe::ErrorCode::OutOfMemory);
    case KK_ERR_ENGINE:            return kikoe::error_string(kikoe::ErrorCode::EngineFailed);
    case KK_ERR_INVALID_ARGUMENT:  return kikoe::error_string(kikoe::ErrorCode::InvalidArgument);
    default:                       return "unknown error";
    }
}

kk_engine* kk_engine_create(const kk_engine_params* params, int* err)
{
    auto fail = [&](int code) -> kk_engine* {
        if (err) *err = code;
        return nullptr;
    };

    if (err) *err = KK_OK;
    if (params == nullptr || params->model_path == nullptr || params->model_path[0] == '\0') {
        return fail(KK_ERR_INVALID_ARGUMENT);
    }
    if (params->vad != 0 && (params->vad_model_path == nullptr || params->vad_model_path[0] == '\0')) {
        return fail(KK_ERR_INVALID_ARGUMENT); // vad requested without a model path
    }

    try {
        kikoe::EngineOptions opts;
        opts.model_path = params->model_path;
        opts.n_threads = params->n_threads;
        opts.use_gpu = params->use_gpu != 0;

        kikoe::ErrorCode ecode = kikoe::ErrorCode::Ok;
        auto engine = kikoe::Engine::create(opts, ecode);
        if (!engine) return fail(ecode == kikoe::ErrorCode::Ok ? KK_ERR_ENGINE : to_kk_error(ecode));

        auto* e = new (std::nothrow) kk_engine{};
        if (!e) return fail(KK_ERR_OUT_OF_MEMORY);
        e->engine_options = std::move(opts);
        e->vad = params->vad != 0;
        if (params->vad_model_path) e->vad_model_path = params->vad_model_path;
        e->engine = std::move(engine);
        return e;
    } catch (...) {
        return fail(KK_ERR_ENGINE);
    }
}

void kk_engine_free(kk_engine* engine)
{
    delete engine; // unique_ptr member releases the C++ engine
}

const char* kk_model_cache_dir(void)
{
    // Function-local static keeps the string alive for the process lifetime.
    static const std::string dir = kikoe::model_cache_dir();
    return dir.c_str();
}

int kk_download_model(const char* name, kk_progress_cb on_progress, void* user)
{
    if (name == nullptr || name[0] == '\0') return KK_ERR_INVALID_ARGUMENT;
    const kikoe::ModelEntry* entry = kikoe::find_model(name);
    if (entry == nullptr) return KK_ERR_INVALID_ARGUMENT;

    // Adapt (kk_progress_cb, user) to the (bytes, total, user) shape the
    // model manager uses.
    auto adapter = [](unsigned long long done, unsigned long long total, void* u) {
        auto* args = static_cast<std::pair<kk_progress_cb, void*>*>(u);
        if (args && args->first) {
            const int pct = total == 0 ? 0 : static_cast<int>((done * 100) / total);
            args->first(pct, args->second);
        }
    };
    std::pair<kk_progress_cb, void*> args{on_progress, user};
    kikoe::ErrorCode err = kikoe::download_model(*entry, adapter, &args);
    return to_kk_error(err);
}

void kk_cancel(kk_engine* engine)
{
    if (engine && engine->engine) engine->engine->cancel();
}

namespace {

int run_transcribe(kk_engine* engine,
                   const float* samples,
                   unsigned long long n_samples,
                   const kk_options* options,
                   kk_progress_cb on_progress,
                   kk_segment_cb on_segment,
                   void* user)
{
    kikoe::TranscribeOptions topts = to_transcribe_options(options);
    topts.vad = engine->vad;
    topts.vad_model_path = engine->vad_model_path;

    // Bridge the C segment callback onto the C++ one.
    struct Bridge {
        kk_segment_cb cb;
        void* user;
    } bridge{on_segment, user};

    auto cb = [](const kikoe::Segment& seg, void* user_data) {
        auto* b = static_cast<Bridge*>(user_data);
        if (b->cb) {
            kk_segment cseg{seg.start_ms, seg.end_ms, seg.text.c_str()};
            b->cb(&cseg, b->user);
        }
    };

    kikoe::SegmentCallback segment_fn = nullptr;
    void* user_fn = nullptr;
    if (on_segment) {
        segment_fn = cb; // captureless lambda converts to a function pointer
        user_fn = &bridge;
    }

    engine->last_segments.clear();
    kikoe::ErrorCode terr = engine->engine->transcribe(
        samples, static_cast<size_t>(n_samples), topts,
        on_progress, segment_fn, user_fn,
        &engine->last_segments);
    return to_kk_error(terr);
}

} // namespace

int kk_transcribe(kk_engine* engine,
                  const char* media_path,
                  const kk_options* options,
                  kk_progress_cb on_progress,
                  kk_segment_cb on_segment,
                  void* user)
{
    if (engine == nullptr || engine->engine == nullptr) return KK_ERR_INVALID_ARGUMENT;
    if (media_path == nullptr || media_path[0] == '\0') return KK_ERR_INVALID_ARGUMENT;

    try {
        kikoe::PcmAudio audio;
        kikoe::ErrorCode lerr = kikoe::load_pcm_any(media_path, audio);
        if (lerr != kikoe::ErrorCode::Ok) return to_kk_error(lerr);
        return run_transcribe(engine, audio.samples.data(), audio.samples.size(),
                              options, on_progress, on_segment, user);
    } catch (...) {
        return KK_ERR_ENGINE;
    }
}

int kk_transcribe_pcm(kk_engine* engine,
                      const float* samples,
                      unsigned long long n_samples,
                      const kk_options* options,
                      kk_progress_cb on_progress,
                      kk_segment_cb on_segment,
                      void* user)
{
    if (engine == nullptr || engine->engine == nullptr) return KK_ERR_INVALID_ARGUMENT;
    if (samples == nullptr || n_samples == 0) return KK_ERR_INVALID_ARGUMENT;

    try {
        return run_transcribe(engine, samples, n_samples, options, on_progress, on_segment, user);
    } catch (...) {
        return KK_ERR_ENGINE;
    }
}

int kk_last_segment_count(const kk_engine* engine)
{
    if (engine == nullptr) return 0;
    return static_cast<int>(engine->last_segments.size());
}

int kk_last_segment_get(const kk_engine* engine, int index, kk_segment* out_segment)
{
    if (engine == nullptr || out_segment == nullptr) return KK_ERR_INVALID_ARGUMENT;
    if (index < 0 || static_cast<size_t>(index) >= engine->last_segments.size()) {
        return KK_ERR_INVALID_ARGUMENT;
    }
    const kikoe::Segment& seg = engine->last_segments[static_cast<size_t>(index)];
    out_segment->start_ms = seg.start_ms;
    out_segment->end_ms = seg.end_ms;
    out_segment->text = seg.text.c_str();
    return KK_OK;
}

int kk_format_last(const kk_engine* engine,
                   const char* format,
                   char* out_buffer,
                   unsigned long long buffer_size,
                   unsigned long long* out_written)
{
    if (engine == nullptr || format == nullptr) return KK_ERR_INVALID_ARGUMENT;

    kikoe::OutputFormat fmt;
    if (!kikoe::parse_format(format, fmt)) return KK_ERR_INVALID_ARGUMENT;

    const std::string rendered = kikoe::format_segments(engine->last_segments, fmt);
    const unsigned long long needed = static_cast<unsigned long long>(rendered.size()) + 1; // NUL

    if (out_written) *out_written = needed;

    if (out_buffer == nullptr || buffer_size == 0) {
        return KK_OK; // query mode
    }

    const unsigned long long copy = needed < buffer_size ? needed : buffer_size;
    std::memcpy(out_buffer, rendered.c_str(), static_cast<size_t>(copy - 1));
    out_buffer[copy - 1] = '\0';
    return KK_OK;
}
