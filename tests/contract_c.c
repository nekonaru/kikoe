/*
 * Kikoe C API contract test. Calls the public surface exactly the way an
 * FFI consumer (Dart, Kotlin, C) would, and verifies the documented
 * contract: error codes, no crashes, no NULL surprises.
 *
 * Builds as C99 and links against kikoe-core.
 */
#include "kikoe.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
    int err = -1;

    assert(kk_abi_version() >= 1);
    assert(kk_version_string() != NULL && strlen(kk_version_string()) > 0);
    assert(kk_error_string(KK_OK) != NULL);
    assert(kk_error_string(KK_ERR_INVALID_ARGUMENT) != NULL);
    assert(kk_error_string(KK_ERR_AUDIO_TOO_LONG) != NULL);
    assert(kk_error_string(9999) != NULL); // unknown codes still map to a string

    /* create: invalid arguments */
    assert(kk_engine_create(NULL, &err) == NULL && err != KK_OK);
    {
        kk_engine_params p = {0};
        assert(kk_engine_create(&p, &err) == NULL && err == KK_ERR_INVALID_ARGUMENT);
    }

    /* create: model that does not exist */
    {
        kk_engine_params p = {0};
        p.model_path = "kikoe-test-no-such-model-12345.bin";
        p.n_threads = 0;
        assert(kk_engine_create(&p, &err) == NULL && err == KK_ERR_MODEL_NOT_FOUND);
    }

    /* create: VAD requested without a path */
    {
        kk_engine_params p = {0};
        p.model_path = "kikoe-test-no-such-model-12345.bin";
        p.vad = 1;
        p.vad_model_path = NULL;
        assert(kk_engine_create(&p, &err) == NULL && err == KK_ERR_INVALID_ARGUMENT);
    }

    /* transcribe: invalid arguments */
    assert(kk_transcribe(NULL, "x", NULL, NULL, NULL, NULL) == KK_ERR_INVALID_ARGUMENT);
    assert(kk_transcribe_pcm(NULL, NULL, 0, NULL, NULL, NULL, NULL) == KK_ERR_INVALID_ARGUMENT);

    /* segment access: invalid arguments */
    assert(kk_last_segment_count(NULL) == 0);
    {
        kk_segment seg;
        assert(kk_last_segment_get(NULL, 0, &seg) == KK_ERR_INVALID_ARGUMENT);
    }

    /* format_last: invalid arguments and query mode */
    {
        unsigned long long written = 0;
        assert(kk_format_last(NULL, "txt", NULL, 0, &written) == KK_ERR_INVALID_ARGUMENT);
        assert(kk_format_last(NULL, "bogus", NULL, 0, &written) == KK_ERR_INVALID_ARGUMENT);
    }

    /* model cache dir: always available */
    assert(kk_model_cache_dir() != NULL && strlen(kk_model_cache_dir()) > 0);

    /* download: unknown registry name */
    assert(kk_download_model("not-a-model", NULL, NULL) == KK_ERR_INVALID_ARGUMENT);
    assert(kk_download_model(NULL, NULL, NULL) == KK_ERR_INVALID_ARGUMENT);

    /* Optional end-to-end via PCM: same as above but through kk_transcribe_pcm. */
    {
        const char* model = getenv("KIKOE_TEST_MODEL");
        const char* wav = getenv("KIKOE_TEST_WAV");
        if (model && wav) {
            /* Read the WAV into memory manually: minimal RIFF PCM16 parser. */
            FILE* f = fopen(wav, "rb");
            assert(f != NULL);
            fseek(f, 0, SEEK_END);
            long size = ftell(f);
            fseek(f, 0, SEEK_SET);
            unsigned char* buf = (unsigned char*)malloc((size_t)size);
            assert(buf != NULL);
            assert(fread(buf, 1, (size_t)size, f) == (size_t)size);
            fclose(f);

            /* Locate the data chunk. */
            const unsigned char* data = NULL;
            unsigned int data_len = 0;
            for (long i = 12; i + 8 <= size; ) {
                unsigned int chunk = (unsigned int)((unsigned int)buf[i + 4] |
                                                   ((unsigned int)buf[i + 5] << 8) |
                                                   ((unsigned int)buf[i + 6] << 16) |
                                                   ((unsigned int)buf[i + 7] << 24));
                if (memcmp(buf + i, "data", 4) == 0) { data = buf + i + 8; data_len = chunk; break; }
                i += 8 + chunk + (chunk & 1);
            }
            assert(data != NULL);
            const size_t n_samples = data_len / 2;
            float* pcm = (float*)malloc(n_samples * sizeof(float));
            assert(pcm != NULL);
            for (size_t i = 0; i < n_samples; ++i) {
                short v = (short)((data[i * 2] | (data[i * 2 + 1] << 8)));
                pcm[i] = (float)v / 32768.0f;
            }

            kk_engine_params p = {0};
            p.model_path = model;
            p.n_threads = 0;
            int cerr = -1;
            kk_engine* e = kk_engine_create(&p, &cerr);
            assert(e != NULL && cerr == KK_OK);
            kk_options opts = {0};
            opts.language = "en";
            assert(kk_transcribe_pcm(e, pcm, (unsigned long long)n_samples, &opts, NULL, NULL, NULL) == KK_OK);
            int count = kk_last_segment_count(e);
            printf("kk_transcribe_pcm segments: %d\n", count);
            assert(count > 0);
            kk_engine_free(e);
            free(pcm);
            free(buf);
            printf("end-to-end PCM transcription ok\n");
        }
    }

    /* free: NULL is a no-op */
    kk_engine_free(NULL);
    kk_cancel(NULL);

    /* Optional end-to-end: set KIKOE_TEST_MODEL to a ggml model and
     * KIKOE_TEST_WAV to a 16 kHz mono WAV to exercise the full invoke path. */
    {
        const char* model = getenv("KIKOE_TEST_MODEL");
        const char* wav = getenv("KIKOE_TEST_WAV");
        if (model && wav) {
            kk_engine_params p = {0};
            p.model_path = model;
            int cerr = -1;
            kk_engine* e = kk_engine_create(&p, &cerr);
            assert(e != NULL && cerr == KK_OK);
            assert(kk_transcribe(e, wav, NULL, NULL, NULL, NULL) == KK_OK);
            assert(kk_last_segment_count(e) > 0);
            {
                kk_segment seg;
                assert(kk_last_segment_get(e, 0, &seg) == KK_OK);
                assert(seg.end_ms >= seg.start_ms);
                assert(seg.text != NULL);
            }
            {
                unsigned long long needed = 0;
                assert(kk_format_last(e, "srt", NULL, 0, &needed) == KK_OK);
                assert(needed > 10);
                char* buf = (char*)malloc((size_t)needed);
                assert(buf != NULL);
                unsigned long long written = 0;
                assert(kk_format_last(e, "srt", buf, needed, &written) == KK_OK);
                assert(strstr(buf, "-->") != NULL);
                free(buf);
            }
            kk_engine_free(e);
            printf("end-to-end transcription ok\n");
        } else {
            printf("skip: KIKOE_TEST_MODEL/KIKOE_TEST_WAV not set\n");
        }
    }

    printf("kikoe C API contract ok\n");
    return 0;
}
