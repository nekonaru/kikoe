#ifndef KIKOE_H
#define KIKOE_H

/*
 * Kikoe public C API.
 *
 * ABI version: KK_ABI_VERSION_MAJOR.KK_ABI_VERSION_MINOR. The version is bumped
 * for any change to this header. Check kk_abi_version() before calling anything
 * else if you are unsure what you linked against.
 *
 * Threading: kk_transcribe() blocks the calling thread. Callbacks fire on that
 * same thread. kk_cancel() may be called from any thread.
 *
 * Memory: strings returned by kk_segment_text_* and kk_format_last stay valid
 * until the next call to kk_transcribe() or kk_engine_free() on the same
 * engine. Caller never frees them. All other pointers passed in are borrowed.
 *
 * Errors: every function returns a kk_error code (0 = ok). No C++ exception ever
 * crosses this boundary.
 */

#ifdef KIKOE_STATIC
#  define KK_API
#else
#  if defined(_WIN32)
#    if defined(KIKOE_BUILD_SHARED)
#      define KK_API __declspec(dllexport)
#    elif defined(KIKOE_SHARED)
#      define KK_API __declspec(dllimport)
#    else
#      define KK_API
#    endif
#  else
#    if defined(KIKOE_BUILD_SHARED)
#      define KK_API __attribute__((visibility("default")))
#    else
#      define KK_API
#    endif
#  endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define KK_ABI_VERSION_MAJOR 0
#define KK_ABI_VERSION_MINOR 1

typedef struct kk_engine kk_engine;

typedef struct {
    const char* model_path;  // required; UTF-8 path to a ggml model
    int         n_threads;   // 0 = automatic
    int         use_gpu;     // 0 or 1; requires a GPU-enabled build
    int         vad;         // 0 or 1; filter silence (requires vad_model_path)
    const char* vad_model_path; // optional; may be NULL
} kk_engine_params;

typedef struct {
    const char* language;       // "id", "en", "auto", ...; may be NULL for auto
    int         translate;      // 0 or 1
    const char* initial_prompt; // may be NULL
} kk_options;

typedef struct {
    long long start_ms;
    long long end_ms;
    const char* text; // UTF-8, valid until the next kk_transcribe/kk_engine_free
} kk_segment;

typedef void (*kk_progress_cb)(int percent, void* user);
typedef void (*kk_segment_cb)(const kk_segment* seg, void* user);

/* Returns KK_ABI_VERSION_MAJOR * 100 + KK_ABI_VERSION_MINOR. */
KK_API int kk_abi_version(void);

/* Static, never NULL. For example "0.1.0". */
KK_API const char* kk_version_string(void);

/* kk_error codes. */
enum kk_error {
    KK_OK = 0,
    KK_ERR_IO = 1,
    KK_ERR_INVALID_MEDIA = 2,
    KK_ERR_UNSUPPORTED_FORMAT = 3,
    KK_ERR_DECODER_FAILED = 4,
    KK_ERR_DECODER_NOT_FOUND = 5,
    KK_ERR_MODEL_NOT_FOUND = 6,
    KK_ERR_MODEL_CHECKSUM = 7,
    KK_ERR_CANCELLED = 8,
    KK_ERR_OUT_OF_MEMORY = 9,
    KK_ERR_ENGINE = 10,
    KK_ERR_INVALID_ARGUMENT = 11,
};

/* Human readable description of an error code. Never NULL. */
KK_API const char* kk_error_string(int err);

/* Create an engine. Returns NULL and sets *err on failure. */
KK_API kk_engine* kk_engine_create(const kk_engine_params* params, int* err);

/* Transcribe a media file (or WAV). Blocks until done or cancelled.
 * Callbacks and the media path may cross threads safely via kk_cancel().
 * Returns KK_OK or an error code. Segments are also retrievable afterwards
 * with kk_last_segment_* and kk_format_last(). */
KK_API int kk_transcribe(kk_engine* engine,
                         const char* media_path,
                         const kk_options* options,
                         kk_progress_cb on_progress,
                         kk_segment_cb on_segment,
                         void* user);

/* Transcribe raw mono 16 kHz float PCM. Same contract as kk_transcribe(),
 * for callers that decode media themselves (for example Android through the
 * platform MediaCodec). `n_samples` is the number of floats, not bytes. */
KK_API int kk_transcribe_pcm(kk_engine* engine,
                             const float* samples,
                             unsigned long long n_samples,
                             const kk_options* options,
                             kk_progress_cb on_progress,
                             kk_segment_cb on_segment,
                             void* user);

/* Request cancellation. May be called from any thread. The running
 * kk_transcribe() returns KK_ERR_CANCELLED at the next checkpoint. */
KK_API void kk_cancel(kk_engine* engine);

/* Number of segments from the last kk_transcribe() call. */
KK_API int kk_last_segment_count(const kk_engine* engine);

/* Copy segment `index` (0-based) into `*out_segment`. The text pointer is
 * borrowed (see header comment). Returns KK_OK or KK_ERR_INVALID_ARGUMENT. */
KK_API int kk_last_segment_get(const kk_engine* engine, int index, kk_segment* out_segment);

/* Render the last transcription. `format` is "txt", "srt", "vtt" or "json".
 * When `out_buffer` is NULL or `buffer_size` == 0, only the required size is
 * stored in *out_written (query mode, nothing is written). Otherwise at most
 * buffer_size bytes are written and *out_written receives the full required
 * size. Returns KK_OK or an error code. */
KK_API int kk_format_last(const kk_engine* engine,
                          const char* format,
                          char* out_buffer,
                          unsigned long long buffer_size,
                          unsigned long long* out_written);

/* Free the engine and everything it owns. NULL is a no-op. */
KK_API void kk_engine_free(kk_engine* engine);

/* Resolved model cache directory. Never NULL. Computed once per process;
 * the returned pointer is valid for the lifetime of the process. */
KK_API const char* kk_model_cache_dir(void);

/* Download a registry model into the cache, verifying SHA-256.
 * on_progress (may be NULL) receives bytes downloaded so far.
 * Returns KK_OK or KK_ERR_MODEL_CHECKSUM/KK_ERR_ENGINE/KK_ERR_INVALID_ARGUMENT. */
KK_API int kk_download_model(const char* name, kk_progress_cb on_progress, void* user);

#ifdef __cplusplus
}
#endif

#endif /* KIKOE_H */
