#include "media_pcm.h"

#include "media_decoder.h"

#include <cctype>

namespace kikoe {

namespace {

bool ends_with_ci(const std::string& s, const std::string& suffix)
{
    if (s.size() < suffix.size()) return false;
    for (size_t i = 0; i < suffix.size(); ++i) {
        if (std::tolower(static_cast<unsigned char>(s[s.size() - suffix.size() + i])) !=
            std::tolower(static_cast<unsigned char>(suffix[i]))) return false;
    }
    return true;
}

} // namespace

ErrorCode load_pcm_any(const std::string& path, PcmAudio& out)
{
    if (ends_with_ci(path, ".wav")) {
        const ErrorCode err = read_wav(path, out);
        if (err == ErrorCode::Ok || err == ErrorCode::Io) {
            return err;
        }
        // Fall through: FFmpeg handles WAVE variants the native reader rejects.
    }
    return decode_media(path, out);
}

} // namespace kikoe
