#include "../core/src/audio/wav_reader.h"
#include "../core/src/engine/engine.h"
#include "../core/src/error.h"
#include "kikoe.h"

#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <vector>

namespace {

std::string temp_path(const char* name)
{
    const char* tmp = std::getenv("TEMP");
    if (!tmp) tmp = std::getenv("TMPDIR");
    if (!tmp) tmp = ".";
    return std::string(tmp) + "/kikoe-test-" + name;
}

// Write a little-endian PCM16 WAV from float samples in [-1, 1).
void write_wav(const std::string& path, uint32_t rate, uint16_t channels,
               uint16_t bits, const std::vector<float>& interleaved)
{
    const uint32_t block_align = channels * (bits / 8);
    const uint32_t byte_rate = rate * block_align;
    const uint32_t data_size = static_cast<uint32_t>(interleaved.size()) * (bits / 8);

    std::ofstream f(path, std::ios::binary);
    auto w16 = [&](uint16_t v) { f.write(reinterpret_cast<const char*>(&v), 2); };
    auto w32 = [&](uint32_t v) { f.write(reinterpret_cast<const char*>(&v), 4); };

    f.write("RIFF", 4); w32(36 + data_size); f.write("WAVE", 4);
    f.write("fmt ", 4); w32(16); w16(1); w16(channels); w32(rate); w32(byte_rate); w16(block_align); w16(bits);
    f.write("data", 4); w32(data_size);
    for (float s : interleaved) {
        if (bits == 16) {
            int16_t v = static_cast<int16_t>(std::lround(s * 32767.0f));
            f.write(reinterpret_cast<const char*>(&v), 2);
        } else if (bits == 8) {
            uint8_t v = static_cast<uint8_t>(std::lround(s * 127.0f + 128.0f));
            f.write(reinterpret_cast<const char*>(&v), 1);
        }
    }
}

std::vector<float> sine(uint32_t rate, double seconds, double freq, size_t channels)
{
    const size_t n = static_cast<size_t>(rate * seconds);
    std::vector<float> out(n * channels);
    for (size_t i = 0; i < n; ++i) {
        const float v = static_cast<float>(std::sin(2.0 * 3.141592653589793 * freq * i / rate) * 0.5);
        for (size_t c = 0; c < channels; ++c) out[i * channels + c] = v;
    }
    return out;
}

void test_wav_roundtrip_16khz_mono()
{
    const std::string p = temp_path("mono.wav");
    write_wav(p, 16000, 1, 16, sine(16000, 0.25, 440.0, 1));
    kikoe::PcmAudio audio;
    const kikoe::ErrorCode err = kikoe::read_wav(p, audio);
    assert(err == kikoe::ErrorCode::Ok);
    assert(audio.samples.size() == 4000);
    assert(std::fabs(audio.duration_seconds - 0.25) < 1e-6);
    std::remove(p.c_str());
}

void test_wav_stereo_downmix()
{
    const std::string p = temp_path("stereo.wav");
    // Left full scale positive, right full scale negative -> average ~ 0.
    std::vector<float> interleaved;
    for (int i = 0; i < 160; ++i) { interleaved.push_back(0.9f); interleaved.push_back(-0.9f); }
    write_wav(p, 16000, 2, 16, interleaved);
    kikoe::PcmAudio audio;
    assert(kikoe::read_wav(p, audio) == kikoe::ErrorCode::Ok);
    assert(audio.samples.size() == 160);
    for (float v : audio.samples) assert(std::fabs(v) < 0.01f);
    std::remove(p.c_str());
}

void test_wav_upsample_32k_to_16k()
{
    const std::string p = temp_path("up.wav");
    write_wav(p, 32000, 1, 16, sine(32000, 0.25, 440.0, 1));
    kikoe::PcmAudio audio;
    assert(kikoe::read_wav(p, audio) == kikoe::ErrorCode::Ok);
    assert(audio.samples.size() == 4000);
    std::remove(p.c_str());
}

void test_wav_8bit()
{
    const std::string p = temp_path("8bit.wav");
    write_wav(p, 16000, 1, 8, sine(16000, 0.1, 440.0, 1));
    kikoe::PcmAudio audio;
    assert(kikoe::read_wav(p, audio) == kikoe::ErrorCode::Ok);
    assert(audio.samples.size() == 1600);
    std::remove(p.c_str());
}

void test_wav_garbage_rejected()
{
    const std::string p = temp_path("garbage.wav");
    { std::ofstream f(p, std::ios::binary); f << "this is not a wav file at all"; }
    kikoe::PcmAudio audio;
    assert(kikoe::read_wav(p, audio) == kikoe::ErrorCode::InvalidMedia);
    std::remove(p.c_str());
}

void test_wav_missing_file()
{
    kikoe::PcmAudio audio;
    assert(kikoe::read_wav(temp_path("does-not-exist-12345.wav"), audio) == kikoe::ErrorCode::Io);
}

void test_engine_rejects_missing_model()
{
    kikoe::EngineOptions opts;
    opts.model_path = temp_path("no-such-model-12345.bin");
    kikoe::ErrorCode err = kikoe::ErrorCode::Ok;
    auto engine = kikoe::Engine::create(opts, err);
    assert(engine == nullptr);
    assert(err == kikoe::ErrorCode::ModelNotFound);
}

void test_engine_rejects_empty_model_path()
{
    kikoe::EngineOptions opts;
    kikoe::ErrorCode err = kikoe::ErrorCode::Ok;
    auto engine = kikoe::Engine::create(opts, err);
    assert(engine == nullptr);
    assert(err == kikoe::ErrorCode::ModelNotFound);
}

// Full transcription runs only when KIKOE_TEST_MODEL points at a ggml model.
// Skipped silently otherwise so CI stays hermetic.
void test_transcribe_with_model_if_present()
{
    const char* model = std::getenv("KIKOE_TEST_MODEL");
    const char* wav = std::getenv("KIKOE_TEST_WAV");
    if (!model || !wav) {
        std::printf("skip: KIKOE_TEST_MODEL/KIKOE_TEST_WAV not set\n");
        return;
    }
    kikoe::PcmAudio audio;
    assert(kikoe::read_wav(wav, audio) == kikoe::ErrorCode::Ok);

    kikoe::EngineOptions eopts;
    eopts.model_path = model;
    kikoe::ErrorCode err = kikoe::ErrorCode::Ok;
    auto engine = kikoe::Engine::create(eopts, err);
    assert(engine != nullptr);

    kikoe::TranscribeOptions topts;
    kikoe::SegmentList segments;
    err = engine->transcribe(audio.samples.data(), audio.samples.size(), topts,
                             nullptr, nullptr, nullptr, &segments);
    assert(err == kikoe::ErrorCode::Ok);
    assert(!segments.empty());
    std::printf("transcribed %zu segments\n", segments.size());
}

} // namespace

int main()
{
    test_wav_roundtrip_16khz_mono();
    test_wav_stereo_downmix();
    test_wav_upsample_32k_to_16k();
    test_wav_8bit();
    test_wav_garbage_rejected();
    test_wav_missing_file();
    test_engine_rejects_missing_model();
    test_engine_rejects_empty_model_path();

    int version = kk_abi_version();
    assert(version >= 1);

    test_transcribe_with_model_if_present();
    std::printf("kikoe core ok (abi %d)\n", version);
    return 0;
}
