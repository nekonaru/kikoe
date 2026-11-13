#ifndef KIKOE_WAV_READER_H
#define KIKOE_WAV_READER_H

#include "../error.h"

#include <string>
#include <vector>

namespace kikoe {

struct PcmAudio {
    std::vector<float> samples; // mono, 16 kHz, normalized to [-1, 1)
    double duration_seconds = 0.0;
};

// Read a RIFF/WAVE file into mono 16 kHz float PCM.
//
// Supports PCM 8/16/24/32-bit integer and 32-bit float payloads, any channel
// count (downmixed by averaging), and any sample rate (resampled with linear
// interpolation). Linear resampling is functional but not studio quality;
// for non-WAV media the FFmpeg decoder (media_decoder.h) is preferred.
//
// On failure returns ErrorCode != Ok and leaves `out` untouched.
ErrorCode read_wav(const std::string& path, PcmAudio& out);

} // namespace kikoe

#endif // KIKOE_WAV_READER_H
