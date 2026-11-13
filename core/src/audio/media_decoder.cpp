#include "media_decoder.h"

#include <array>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#endif

namespace kikoe {

#ifdef _WIN32

namespace {

// Quote an argument for CreateProcess (Windows) rules: wrap in quotes,
// backslash-escape embedded quotes.
std::string quote_arg_win(const std::string& s)
{
    std::string out = "\"";
    for (char c : s) {
        if (c == '"') out += "\\\"";
        else out += c;
    }
    out += "\"";
    return out;
}

} // namespace
#endif

#ifdef _WIN32

// Spawn ffmpeg directly with CreateProcess: no shell, no quoting ambiguity,
// no dependence on shell parsing. PATH is used when ffmpeg_path has no
// directory component.
ErrorCode decode_media_win(const std::string& path, PcmAudio& out, const std::string& ffmpeg_path)
{
    SECURITY_ATTRIBUTES sa{};
    sa.nLength = sizeof(sa);
    sa.bInheritHandle = TRUE;

    HANDLE pcm_read = nullptr, pcm_write = nullptr;
    if (!CreatePipe(&pcm_read, &pcm_write, &sa, 0)) return ErrorCode::DecoderNotFound;
    SetHandleInformation(pcm_read, HANDLE_FLAG_INHERIT, 0);

    HANDLE nul_err = CreateFileA("NUL", GENERIC_WRITE, FILE_SHARE_WRITE, &sa,
                                 OPEN_EXISTING, 0, nullptr);

    STARTUPINFOA si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = pcm_write;
    si.hStdError = (nul_err != INVALID_HANDLE_VALUE) ? nul_err : GetStdHandle(STD_ERROR_HANDLE);
    si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);

    std::string cmdline = quote_arg_win(ffmpeg_path) +
        " -nostdin -v error -i " + quote_arg_win(path) +
        " -vn -ar 16000 -ac 1 -f f32le -";

    PROCESS_INFORMATION pi{};
    const BOOL ok = CreateProcessA(nullptr, cmdline.data(), nullptr, nullptr,
                                   TRUE, 0, nullptr, nullptr, &si, &pi);

    CloseHandle(pcm_write);
    if (nul_err != INVALID_HANDLE_VALUE) CloseHandle(nul_err);
    if (!ok) {
        CloseHandle(pcm_read);
        // Typical cause: ffmpeg not on PATH (ERROR_FILE_NOT_FOUND).
        return ErrorCode::DecoderNotFound;
    }

    std::vector<uint8_t> bytes;
    bytes.reserve(1 << 20);
    std::array<uint8_t, 65536> chunk{};
    DWORD n = 0;
    while (ReadFile(pcm_read, chunk.data(), static_cast<DWORD>(chunk.size()), &n, nullptr) && n > 0) {
        bytes.insert(bytes.end(), chunk.begin(), chunk.begin() + n);
    }
    CloseHandle(pcm_read);

    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD rc = 0;
    GetExitCodeProcess(pi.hProcess, &rc);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    if (rc != 0) return ErrorCode::DecoderFailed;
    if (bytes.empty() || bytes.size() % sizeof(float) != 0) return ErrorCode::InvalidMedia;

    PcmAudio result;
    const size_t count = bytes.size() / sizeof(float);
    result.samples.resize(count);
    std::memcpy(result.samples.data(), bytes.data(), bytes.size());
    result.duration_seconds = static_cast<double>(count) / 16000.0;
    out = std::move(result);
    return ErrorCode::Ok;
}

#else // POSIX

namespace {

std::string shell_quote(const std::string& s)
{
    // Single-quote and escape embedded single quotes.
    std::string out = "'";
    for (char c : s) {
        if (c == '\'') out += "'\\''";
        else out += c;
    }
    out += "'";
    return out;
}

ErrorCode decode_media_popen(const std::string& path, PcmAudio& out, const std::string& ffmpeg_path)
{
    std::string cmd = shell_quote(ffmpeg_path) +
        " -nostdin -v error -i " + shell_quote(path) +
        " -vn -ar 16000 -ac 1 -f f32le - 2>/dev/null";

    FILE* pipe = popen(cmd.c_str(), "rb");
    if (pipe == nullptr) return ErrorCode::DecoderNotFound;

    std::vector<uint8_t> bytes;
    bytes.reserve(1 << 20);
    std::array<uint8_t, 65536> chunk{};
    size_t n;
    while ((n = std::fread(chunk.data(), 1, chunk.size(), pipe)) > 0) {
        bytes.insert(bytes.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(n));
    }
    const int rc = pclose(pipe);

    if (rc != 0) return ErrorCode::DecoderFailed;
    if (bytes.empty() || bytes.size() % sizeof(float) != 0) return ErrorCode::InvalidMedia;

    PcmAudio result;
    const size_t count = bytes.size() / sizeof(float);
    result.samples.resize(count);
    std::memcpy(result.samples.data(), bytes.data(), bytes.size());
    result.duration_seconds = static_cast<double>(count) / 16000.0;
    out = std::move(result);
    return ErrorCode::Ok;
}

} // namespace

#endif

ErrorCode decode_media(const std::string& path, PcmAudio& out, const std::string& ffmpeg_path)
{
    if (ffmpeg_path.empty()) return ErrorCode::DecoderNotFound;
    for (char c : path) {
        if (c == '"') return ErrorCode::InvalidArgument; // keep command lines predictable
    }
#ifdef _WIN32
    return decode_media_win(path, out, ffmpeg_path);
#else
    return decode_media_popen(path, out, ffmpeg_path);
#endif
}

} // namespace kikoe
