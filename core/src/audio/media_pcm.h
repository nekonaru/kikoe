#ifndef KIKOE_MEDIA_PCM_H
#define KIKOE_MEDIA_PCM_H

#include "../error.h"
#include "wav_reader.h"

#include <string>

namespace kikoe {

// Load any supported media into mono 16 kHz float PCM.
//
// .wav files go through the native reader first; on failure (or for any other
// extension) the FFmpeg decoder is used. Returns Ok or an error code.
ErrorCode load_pcm_any(const std::string& path, PcmAudio& out);

} // namespace kikoe

#endif // KIKOE_MEDIA_PCM_H
