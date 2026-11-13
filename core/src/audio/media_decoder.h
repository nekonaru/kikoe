#ifndef KIKOE_MEDIA_DECODER_H
#define KIKOE_MEDIA_DECODER_H

#include "../error.h"
#include "../audio/wav_reader.h"

#include <string>

namespace kikoe {

// Decode any media container FFmpeg understands into mono 16 kHz float PCM.
//
// FFmpeg runs as a separate child process; Kikoe never links libav* and does
// not distribute ffmpeg. The decoder is a thin adapter so it can be replaced
// by a platform-native decoder later without touching the engine.
//
// `ffmpeg_path` defaults to "ffmpeg" (resolved via PATH). Any literal `"`
// in the input path is rejected on Windows to keep the popen command line
// safe.
ErrorCode decode_media(const std::string& path, PcmAudio& out, const std::string& ffmpeg_path = "ffmpeg");

} // namespace kikoe

#endif // KIKOE_MEDIA_DECODER_H
