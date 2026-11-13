#include "wav_reader.h"

#include <cstdint>
#include <cstring>
#include <fstream>
#include <limits>
#include <vector>

namespace kikoe {

namespace {

struct WavInfo {
    uint16_t audio_format = 0; // 1 = PCM integer, 3 = IEEE float
    uint16_t channels = 0;
    uint32_t sample_rate = 0;
    uint16_t bits_per_sample = 0;
    uint64_t data_offset = 0;
    uint64_t data_size = 0;
};

template <typename T>
T read_le(const uint8_t* p)
{
    T v;
    std::memcpy(&v, p, sizeof(T));
    return v; // x86/ARM are little endian; file data is little endian too
}

bool parse_wav_header(const uint8_t* buf, size_t size, WavInfo& info, std::string& why)
{
    if (size < 12 || std::memcmp(buf, "RIFF", 4) != 0 || std::memcmp(buf + 8, "WAVE", 4) != 0) {
        why = "not a RIFF/WAVE file";
        return false;
    }

    size_t pos = 12;
    bool have_fmt = false;
    bool have_data = false;
    while (pos + 8 <= size && !(have_fmt && have_data)) {
        const char* id = reinterpret_cast<const char*>(buf + pos);
        uint32_t chunk_size = read_le<uint32_t>(buf + pos + 4);
        uint64_t payload = pos + 8;
        if (payload + chunk_size > size) {
            why = "truncated WAVE chunk";
            return false;
        }
        if (std::memcmp(id, "fmt ", 4) == 0) {
            if (chunk_size < 16) { why = "fmt chunk too small"; return false; }
            info.audio_format = read_le<uint16_t>(buf + payload);
            info.channels = read_le<uint16_t>(buf + payload + 2);
            info.sample_rate = read_le<uint32_t>(buf + payload + 4);
            info.bits_per_sample = read_le<uint16_t>(buf + payload + 14);
            have_fmt = true;
        } else if (std::memcmp(id, "data", 4) == 0) {
            info.data_offset = payload;
            info.data_size = chunk_size;
            have_data = true;
        }
        // Chunks are word aligned in RIFF.
        pos = static_cast<size_t>(payload + chunk_size + (chunk_size & 1));
    }

    if (!have_fmt || !have_data) {
        why = "missing fmt or data chunk";
        return false;
    }
    if (info.audio_format != 1 && info.audio_format != 3) {
        why = "unsupported WAVE encoding (need PCM or float)";
        return false;
    }
    if (info.channels == 0 || info.sample_rate == 0) {
        why = "invalid WAVE channel count or sample rate";
        return false;
    }
    const uint16_t bps = info.bits_per_sample;
    const uint16_t ch = info.channels;
    if (info.audio_format == 1 && bps != 8 && bps != 16 && bps != 24 && bps != 32) {
        why = "unsupported PCM bit depth";
        return false;
    }
    if (info.audio_format == 3 && bps != 32) {
        why = "unsupported float bit depth (need 32-bit)";
        return false;
    }
    if (bps % 8 != 0 || bps == 0) { why = "invalid bit depth"; return false; }
    (void)ch;
    return true;
}

float decode_sample(const uint8_t* p, uint16_t format, uint16_t bps)
{
    if (format == 3) { // IEEE float 32-bit
        return read_le<float>(p);
    }
    switch (bps) {
    case 8:
        return (static_cast<float>(p[0]) - 128.0f) / 128.0f;
    case 16: {
        int16_t v = read_le<int16_t>(p);
        return static_cast<float>(v) / 32768.0f;
    }
    case 24: {
        uint32_t v = (static_cast<uint32_t>(p[0]) << 8) |
                     (static_cast<uint32_t>(p[1]) << 16) |
                     (static_cast<uint32_t>(p[2]) << 24);
        if (v & 0x80000000u) v |= 0xFF000000u; // sign extend
        return static_cast<float>(static_cast<int32_t>(v) >> 8) / 8388608.0f;
    }
    case 32: {
        int32_t v = read_le<int32_t>(p);
        return static_cast<float>(v) / 2147483648.0f;
    }
    }
    return 0.0f;
}

std::vector<float> resample_linear(const std::vector<float>& in,
                                   uint32_t in_rate,
                                   uint32_t out_rate)
{
    if (in_rate == out_rate || in.empty()) return in;
    const double ratio = static_cast<double>(in_rate) / static_cast<double>(out_rate);
    const size_t out_n = static_cast<size_t>(static_cast<double>(in.size()) / ratio);
    std::vector<float> out(out_n);
    for (size_t i = 0; i < out_n; ++i) {
        const double src = static_cast<double>(i) * ratio;
        const size_t i0 = static_cast<size_t>(src);
        const size_t i1 = (i0 + 1 < in.size()) ? i0 + 1 : i0;
        const float frac = static_cast<float>(src - static_cast<double>(i0));
        out[i] = in[i0] * (1.0f - frac) + in[i1] * frac;
    }
    return out;
}

} // namespace

ErrorCode read_wav(const std::string& path, PcmAudio& out)
{
    std::ifstream file(path, std::ios::binary | std::ios::ate);
    if (!file) return ErrorCode::Io;
    const std::streamoff size_off = file.tellg();
    if (size_off <= 0) return ErrorCode::InvalidMedia;
    const size_t size = static_cast<size_t>(size_off);

    std::vector<uint8_t> buf(size);
    file.seekg(0, std::ios::beg);
    if (!file.read(reinterpret_cast<char*>(buf.data()), static_cast<std::streamsize>(size))) {
        return ErrorCode::Io;
    }

    WavInfo info;
    std::string why;
    if (!parse_wav_header(buf.data(), buf.size(), info, why)) {
        return ErrorCode::InvalidMedia;
    }

    const uint32_t frame_bytes = (static_cast<uint32_t>(info.bits_per_sample) * info.channels) / 8;
    if (frame_bytes == 0) return ErrorCode::InvalidMedia;
    const uint64_t frames = info.data_size / frame_bytes;
    if (frames > static_cast<uint64_t>(std::numeric_limits<size_t>::max() / info.channels)) {
        return ErrorCode::OutOfMemory;
    }

    const uint8_t* payload = buf.data() + info.data_offset;
    std::vector<float> mono(static_cast<size_t>(frames), 0.0f);
    for (uint64_t f = 0; f < frames; ++f) {
        double acc = 0.0;
        for (uint16_t c = 0; c < info.channels; ++c) {
            acc += decode_sample(payload + (f * info.channels + c) * (info.bits_per_sample / 8),
                                 info.audio_format,
                                 info.bits_per_sample);
        }
        mono[static_cast<size_t>(f)] = static_cast<float>(acc / info.channels);
    }

    constexpr uint32_t kTargetRate = 16000;
    PcmAudio result;
    result.samples = resample_linear(mono, info.sample_rate, kTargetRate);
    result.duration_seconds = static_cast<double>(result.samples.size()) / kTargetRate;
    out = std::move(result);
    return ErrorCode::Ok;
}

} // namespace kikoe
