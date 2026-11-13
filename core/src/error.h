#ifndef KIKOE_ERROR_H
#define KIKOE_ERROR_H

namespace kikoe {

enum class ErrorCode {
    Ok = 0,
    Io,                // file open/read/write failed
    InvalidMedia,      // unreadable or malformed media container
    UnsupportedFormat, // media is readable but its codec/container is not supported
    DecoderFailed,     // external decoder (ffmpeg) ran but failed
    DecoderNotFound,   // ffmpeg binary not available on this system
    ModelNotFound,     // model path does not exist and cache is empty
    ModelChecksum,     // downloaded model failed SHA-256 verification
    Cancelled,         // user cancelled the operation
    OutOfMemory,       // allocation failure or unexpectedly small buffers
    EngineFailed,      // whisper.cpp returned an internal error
    InvalidArgument,   // caller passed an invalid parameter
};

// Human readable, stable English description. Never null.
const char* error_string(ErrorCode code);

} // namespace kikoe

#endif // KIKOE_ERROR_H
