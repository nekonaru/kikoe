#include "error.h"

namespace kikoe {

const char* error_string(ErrorCode code)
{
    switch (code) {
    case ErrorCode::Ok:                return "ok";
    case ErrorCode::Io:                return "i/o error";
    case ErrorCode::InvalidMedia:      return "the media file is unreadable or malformed";
    case ErrorCode::UnsupportedFormat: return "the media format is not supported";
    case ErrorCode::DecoderFailed:     return "the media decoder failed";
    case ErrorCode::DecoderNotFound:   return "ffmpeg is not installed or not on PATH";
    case ErrorCode::ModelNotFound:     return "the whisper model was not found";
    case ErrorCode::ModelChecksum:     return "the downloaded model failed checksum verification";
    case ErrorCode::Cancelled:         return "operation cancelled";
    case ErrorCode::OutOfMemory:       return "out of memory";
    case ErrorCode::EngineFailed:      return "the speech recognition engine failed";
    case ErrorCode::InvalidArgument:   return "invalid argument";
    }
    return "unknown error";
}

} // namespace kikoe
