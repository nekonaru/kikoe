#ifndef KIKOE_ENGINE_H
#define KIKOE_ENGINE_H

#include "../error.h"
#include "../engine/segment.h"

#include <atomic>
#include <memory>
#include <string>
#include <vector>

struct whisper_context;

namespace kikoe {

struct EngineOptions {
    std::string model_path; // required, must exist
    int n_threads = 0;      // 0 = auto (min(4, hardware_concurrency))
    bool use_gpu = false;   // whisper.cpp must be built with a GPU backend
};

struct TranscribeOptions {
    std::string language = "auto";   // "auto", "id", "en", ...
    bool translate = false;          // translate to English instead of transcribing
    std::string initial_prompt;      // may be empty = no prompt
    float no_speech_threshold = 0.6f; // above this, segments are likely silence
    bool vad = false;                // filter silence with whisper.cpp VAD
    std::string vad_model_path;      // required when vad is true
    int quality = 0;                 // 0 balanced, 1 fast, 2 accurate (beam search)
};

using ProgressCallback = void (*)(int percent, void* user);
using SegmentCallback = void (*)(const Segment& segment, void* user);

class Engine {
public:
    // Returns nullptr and sets err on failure. Never throws.
    static std::unique_ptr<Engine> create(const EngineOptions& options, ErrorCode& err);
    ~Engine();

    Engine(const Engine&) = delete;
    Engine& operator=(const Engine&) = delete;

    // Transcribe mono 16 kHz float PCM. Blocks until done, cancelled, or failed.
    // on_progress (may be null) receives 0-100. on_segment (may be null) receives
    // each segment as it is decoded; segments are also returned in `segments`.
    ErrorCode transcribe(const float* samples,
                         size_t n_samples,
                         const TranscribeOptions& options,
                         ProgressCallback on_progress,
                         SegmentCallback on_segment,
                         void* user,
                         SegmentList* segments);

    // Request cancellation. Thread safe. The running transcribe() call returns
    // ErrorCode::Cancelled at the next abort check.
    void cancel();

    // Current progress (0..100) of the running transcribe() while it runs;
    // 0 before start; 100 once done. Relaxed atomic read, always safe.
    int progress_percent() const { return progress_percent_.load(std::memory_order_relaxed); }

private:
    Engine() = default;
    ErrorCode transcribe_impl(const float* samples,
                              size_t n_samples,
                              const TranscribeOptions& options,
                              ProgressCallback on_progress,
                              SegmentCallback on_segment,
                              void* user,
                              SegmentList* segments);

    whisper_context* ctx_ = nullptr;
    int n_threads_ = 1;
    std::atomic<bool> cancel_{false};
    std::atomic<int> progress_percent_{0};
};

} // namespace kikoe

#endif // KIKOE_ENGINE_H
