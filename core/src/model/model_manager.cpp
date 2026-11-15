#include "model_manager.h"

#include "../util/sha256.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#ifdef _WIN32
#define KIKOE_POPEN _popen
#define KIKOE_PCLOSE _pclose
#else
#define KIKOE_POPEN popen
#define KIKOE_PCLOSE pclose
#endif

namespace fs = std::filesystem;

namespace kikoe {

namespace {

std::string env_value(const char* name)
{
#ifdef _WIN32
    char* buf = nullptr;
    size_t len = 0;
    if (_dupenv_s(&buf, &len, name) != 0 || buf == nullptr) return {};
    std::string out(buf);
    free(buf);
    return out;
#else
    const char* v = std::getenv(name);
    return v ? std::string(v) : std::string{};
#endif
}

std::string home_dir()
{
#ifdef _WIN32
    std::string v = env_value("USERPROFILE");
    if (!v.empty()) return v;
    return env_value("HOMEDRIVE") + env_value("HOMEPATH");
#else
    return env_value("HOME");
#endif
}

void ensure_dir(const std::string& dir)
{
    std::error_code ec;
    fs::create_directories(dir, ec);
}

std::string curl_binary()
{
#ifdef _WIN32
    // Windows 10+ ships curl.exe in System32.
    return "curl.exe";
#else
    return "curl";
#endif
}

// Wrap one argument for the shell used by popen/_popen: single-quoted (POSIX)
// or double-quoted (Windows cmd.exe), refusing characters that can break out
// of the quoting context. Fails closed: an impossible argument means the
// download aborts instead of running a mangled command line.
std::string shell_arg(const std::string& s, bool* ok)
{
    if (s.empty()) {
        *ok = false;
        return {};
    }
    for (const unsigned char c : s) {
        if (c < 0x20 || c == 0x7F) { *ok = false; return {}; } // control chars
    }
#ifdef _WIN32
    // Inside cmd.exe double quotes, `%` still expands and `"` ends the quoted
    // context; `!` only with delayed expansion. Refuse all three.
    for (const char c : s) {
        if (c == '"' || c == '%' || c == '!') { *ok = false; return {}; }
    }
    return "\"" + s + "\"";
#else
    std::string out = "'";
    for (const char c : s) {
        if (c == '\'') out += "'\\''";
        else out += c;
    }
    out += "'";
    return out;
#endif
}

} // namespace

std::string model_cache_dir()
{
    std::string base = env_value("KIKOE_CACHE_DIR");
    if (!base.empty()) return base + "/models";

#ifdef _WIN32
    const std::string local = env_value("LOCALAPPDATA");
    if (!local.empty()) return local + "\\kikoe\\models";
    return home_dir() + "\\AppData\\Local\\kikoe\\models";
#elif defined(__APPLE__)
    return home_dir() + "/Library/Caches/kikoe/models";
#else
    std::string xdg = env_value("XDG_CACHE_HOME");
    if (xdg.empty()) xdg = home_dir() + "/.cache";
    return xdg + "/kikoe/models";
#endif
}

std::string resolve_model(const std::string& name, ErrorCode& err)
{
    err = ErrorCode::Ok;

    std::error_code ec;
    if (fs::exists(name, ec)) return name;

    const ModelEntry* entry = find_model(name);
    if (entry == nullptr) {
        err = ErrorCode::ModelNotFound;
        return {};
    }
    const std::string path = model_cache_dir() + "/" + entry->filename;
    if (fs::exists(path, ec)) return path;

    err = ErrorCode::ModelNotFound;
    return {};
}

ErrorCode download_model(const ModelEntry& entry,
                         void (*on_progress)(unsigned long long, unsigned long long, void*),
                         void* user)
{
    const std::string dir = model_cache_dir();
    ensure_dir(dir);
    const std::string final_path = dir + "/" + entry.filename;
    const std::string part_path = final_path + ".part";

    // Fast path: already downloaded and valid.
    if (fs::exists(final_path) && sha256_file(final_path) == entry.sha256) {
        return ErrorCode::Ok;
    }

    unsigned long long existing = 0;
    std::error_code ec;
    if (fs::exists(part_path, ec)) {
        existing = static_cast<unsigned long long>(fs::file_size(part_path, ec));
        // A .part larger than the expected file can only be corrupt.
        if (ec || existing > entry.size) {
            fs::remove(part_path, ec);
            existing = 0;
        }
    }

    // Build the command line with arguments the shell cannot reinterpret.
    bool ok = true;
    const std::string out_arg = shell_arg(part_path, &ok);
    const std::string url_arg = shell_arg(entry.url, &ok);
    if (!ok) return ErrorCode::InvalidArgument;
    std::string cmd = curl_binary() +
        " -fL --retry 3 -C - --progress-bar -o " + out_arg + " " + url_arg;

    FILE* pipe = KIKOE_POPEN(cmd.c_str(), "r");
    if (pipe == nullptr) return ErrorCode::DecoderNotFound; // reuse: external tool missing

    int ch;
    std::string line;
    while ((ch = fgetc(pipe)) != EOF) {
        if (ch == '\n' || ch == '\r') {
            if (on_progress && !line.empty()) {
                // curl --progress-bar prints "###  42.0%" lines; report percent-of-size.
                const size_t pct = line.find('%');
                double frac = 0.0;
                if (pct != std::string::npos && pct > 0) {
                    try { frac = std::stod(line.substr(0, pct)) / 100.0; } catch (...) { frac = 0.0; }
                }
                if (frac > 0.0 && frac <= 1.0) {
                    on_progress(static_cast<unsigned long long>(frac * static_cast<double>(entry.size)),
                                entry.size, user);
                }
                line.clear();
            }
        } else {
            line.push_back(static_cast<char>(ch));
        }
    }
    const int rc = KIKOE_PCLOSE(pipe);

    if (rc != 0) {
        return ErrorCode::EngineFailed; // download failed; .part kept for resume
    }

    if (!fs::exists(part_path)) return ErrorCode::Io;

    if (sha256_file(part_path) != entry.sha256) {
        fs::remove(part_path, ec); // corrupt: do not keep a bad seed for resume
        return ErrorCode::ModelChecksum;
    }

    fs::remove(final_path, ec);
    fs::rename(part_path, final_path, ec);
    if (ec) return ErrorCode::Io;
    if (on_progress) on_progress(entry.size, entry.size, user);
    return ErrorCode::Ok;
}

} // namespace kikoe
