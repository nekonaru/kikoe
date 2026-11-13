/*
 * Kikoe CLI.
 *
 * Inputs: WAV natively (any PCM/float encoding), everything else through
 * FFmpeg as a child process. Outputs: txt, srt, vtt, json. Supports batch
 * (multiple inputs) and model management (--list-models, --download-model).
 */
#include "../core/src/audio/media_pcm.h"
#include "../core/src/audio/media_decoder.h"
#include "../core/src/audio/wav_reader.h"
#include "../core/src/engine/engine.h"
#include "../core/src/error.h"
#include "../core/src/format/formatter.h"
#include "../core/src/model/model_manager.h"
#include "../core/src/model/model_registry.h"
#include "kikoe.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#else
#include <csignal>
#endif

namespace {

kikoe::Engine* g_engine = nullptr;

#ifdef _WIN32
BOOL WINAPI console_ctrl_handler(DWORD type)
{
    if (type == CTRL_C_EVENT || type == CTRL_BREAK_EVENT) {
        if (g_engine) g_engine->cancel();
        return TRUE;
    }
    return FALSE;
}
#else
void sigint_handler(int)
{
    if (g_engine) g_engine->cancel();
}
#endif

void install_ctrl_handler()
{
#ifdef _WIN32
    SetConsoleCtrlHandler(console_ctrl_handler, TRUE);
#else
    std::signal(SIGINT, sigint_handler);
#endif
}

void print_usage(const char* argv0)
{
    std::fprintf(stderr,
        "kikoe %s - offline audio and video transcription\n\n"
        "Usage: %s <input...> [options]\n"
        "       %s --list-models\n"
        "       %s --download-model NAME\n\n"
        "Options:\n"
        "  --model NAME|PATH  Model: registry name (tiny, base, small, medium,\n"
        "                     large, ...) or a path to a .bin file\n"
        "                     (default: small; auto-downloaded is not attempted)\n"
        "  --lang LANG        Language code (id, en, ...) or 'auto' (default: auto)\n"
        "  --threads N        Worker threads (default: min(4, hardware))\n"
        "  --gpu              Use GPU through a whisper.cpp GPU backend\n"
        "                     (build with -DKIKOE_USE_GPU=ON; CPU otherwise)\n"
        "  --vad              Filter silence with Silero VAD (auto-downloads vad-silero)\n"
        "  --translate        Translate speech to English instead of transcribing\n"
        "  --prompt TEXT      Initial prompt / custom vocabulary hint\n"
        "  --format FMTS      Comma separated output formats: txt, srt, vtt, json\n"
        "                     (default: txt, or derived from -o)\n"
        "  -o, --output FILE  Write to FILE (single format, single input)\n"
        "  --outdir DIR       Write <name>.<fmt> files into DIR\n"
        "  -h, --help         Show this help\n\n"
        "Model cache: %s\n",
        "0.1.0", argv0, argv0, argv0, kikoe::model_cache_dir().c_str());
}

void print_error(kikoe::ErrorCode code)
{
    std::fprintf(stderr, "kikoe: %s\n", kikoe::error_string(code));
}

struct Cli {
    std::vector<std::string> inputs;
    std::string model;         // registry name or path; empty until defaulted
    std::string lang = "auto";
    std::string prompt;
    std::string output;        // -o / --output
    std::string outdir;        // --outdir
    std::vector<kikoe::OutputFormat> formats;
    int threads = 0;
    bool translate = false;
    bool gpu = false;
    bool vad = false;
    bool list_models = false;
    std::string download_model;
};

bool ends_with_ci(const std::string& s, const std::string& suffix)
{
    if (s.size() < suffix.size()) return false;
    for (size_t i = 0; i < suffix.size(); ++i) {
        if (std::tolower(static_cast<unsigned char>(s[s.size() - suffix.size() + i])) !=
            std::tolower(static_cast<unsigned char>(suffix[i]))) return false;
    }
    return true;
}

std::string replace_extension(const std::string& path, const std::string& ext)
{
    const size_t slash = path.find_last_of("/\\");
    const size_t dot = path.find_last_of('.');
    if (dot == std::string::npos || (slash != std::string::npos && dot < slash)) {
        return path + "." + ext;
    }
    return path.substr(0, dot) + "." + ext;
}

std::string base_name(const std::string& path)
{
    const size_t slash = path.find_last_of("/\\");
    return slash == std::string::npos ? path : path.substr(slash + 1);
}

std::string join_path(const std::string& dir, const std::string& file)
{
    if (dir.empty()) return file;
    const char last = dir.back();
    if (last == '/' || last == '\\') return dir + file;
#ifdef _WIN32
    return dir + "\\" + file;
#else
    return dir + "/" + file;
#endif
}

bool parse_formats(const std::string& csv, std::vector<kikoe::OutputFormat>& out)
{
    out.clear();
    size_t pos = 0;
    while (pos <= csv.size()) {
        size_t comma = csv.find(',', pos);
        if (comma == std::string::npos) comma = csv.size();
        std::string item = csv.substr(pos, comma - pos);
        while (!item.empty() && std::isspace(static_cast<unsigned char>(item.front()))) item.erase(item.begin());
        while (!item.empty() && std::isspace(static_cast<unsigned char>(item.back()))) item.pop_back();
        kikoe::OutputFormat fmt;
        if (item.empty() || !kikoe::parse_format(item, fmt)) return false;
        out.push_back(fmt);
        pos = comma + 1;
        if (comma == csv.size()) break;
    }
    return !out.empty();
}

bool parse_cli(int argc, char** argv, Cli& cli)
{
    if (argc < 2) return false;
    std::string formats_csv;
    for (int i = 1; i < argc; ++i) {
        const std::string arg = argv[i];
        auto next = [&]() -> const char* {
            if (i + 1 >= argc) return nullptr;
            return argv[++i];
        };
        if (arg == "-h" || arg == "--help") return false;
        else if (arg == "--list-models") cli.list_models = true;
        else if (arg == "--download-model") { const char* v = next(); if (!v) return false; cli.download_model = v; }
        else if (arg == "--model")  { const char* v = next(); if (!v) return false; cli.model = v; }
        else if (arg == "--lang")   { const char* v = next(); if (!v) return false; cli.lang = v; }
        else if (arg == "--prompt") { const char* v = next(); if (!v) return false; cli.prompt = v; }
        else if (arg == "-o" || arg == "--output") { const char* v = next(); if (!v) return false; cli.output = v; }
        else if (arg == "--outdir") { const char* v = next(); if (!v) return false; cli.outdir = v; }
        else if (arg == "--format") { const char* v = next(); if (!v) return false; formats_csv = v; }
        else if (arg == "--threads") {
            const char* v = next(); if (!v) return false;
            try { cli.threads = std::stoi(v); } catch (...) { return false; }
            if (cli.threads < 0) return false;
        }
        else if (arg == "--translate") cli.translate = true;
        else if (arg == "--gpu") cli.gpu = true;
        else if (arg == "--vad") cli.vad = true;
        else if (!arg.empty() && arg[0] == '-') {
            std::fprintf(stderr, "kikoe: unknown option: %s\n", arg.c_str());
            return false;
        }
        else cli.inputs.push_back(arg);
    }

    if (!formats_csv.empty() && !parse_formats(formats_csv, cli.formats)) {
        std::fprintf(stderr, "kikoe: unknown --format value (expected txt, srt, vtt or json)\n");
        return false;
    }
    if (cli.formats.empty()) {
        if (ends_with_ci(cli.output, ".srt"))       cli.formats = {kikoe::OutputFormat::Srt};
        else if (ends_with_ci(cli.output, ".vtt"))  cli.formats = {kikoe::OutputFormat::Vtt};
        else if (ends_with_ci(cli.output, ".json")) cli.formats = {kikoe::OutputFormat::Json};
        else                                        cli.formats = {kikoe::OutputFormat::Txt};
    }
    return true;
}

void progress_cb(int percent, void* user)
{
    auto* prefix = static_cast<const char*>(user);
    std::fprintf(stderr, "\r%s[%3d%%] ", prefix ? prefix : "", percent);
    std::fflush(stderr);
}

void download_progress_cb(unsigned long long done, unsigned long long total, void* /*user*/)
{
    if (total == 0) return;
    std::fprintf(stderr, "\rdownloading... %llu/%llu MB",
                 done / (1024 * 1024), total / (1024 * 1024));
    std::fflush(stderr);
}

void print_models()
{
    std::fprintf(stderr, "Available models (cache: %s):\n\n", kikoe::model_cache_dir().c_str());
    const std::string dir = kikoe::model_cache_dir();
    for (const auto& m : kikoe::model_registry()) {
        const std::string path = dir + "/" + m.filename;
        const bool cached = std::ifstream(path).good();
        std::fprintf(stderr, "  %-20s %6.1f MB  %s\n", m.name,
                     static_cast<double>(m.size) / (1024.0 * 1024.0),
                     cached ? "[cached]" : "");
    }
    std::fprintf(stderr, "\nDownload with: kikoe --download-model NAME\n");
}

} // namespace

int main(int argc, char** argv)
{
    Cli cli;
    if (!parse_cli(argc, argv, cli)) {
        print_usage(argv[0]);
        return argc < 2 ? 1 : 0;
    }

    if (cli.list_models) {
        print_models();
        return 0;
    }

    if (!cli.download_model.empty()) {
        const kikoe::ModelEntry* entry = kikoe::find_model(cli.download_model);
        if (!entry) {
            std::fprintf(stderr, "kikoe: unknown model '%s'. See --list-models.\n",
                         cli.download_model.c_str());
            return 2;
        }
        const kikoe::ErrorCode err = kikoe::download_model(*entry, download_progress_cb, nullptr);
        std::fprintf(stderr, "\n");
        if (err != kikoe::ErrorCode::Ok) {
            print_error(err);
            return 3;
        }
        std::fprintf(stderr, "model '%s' ready in %s\n", entry->name, kikoe::model_cache_dir().c_str());
        return 0;
    }

    if (cli.inputs.empty()) {
        print_usage(argv[0]);
        return 1;
    }

    const bool multiple_inputs = cli.inputs.size() > 1;
    if (!cli.output.empty() && multiple_inputs) {
        std::fprintf(stderr, "kikoe: -o/--output needs a single input; use --outdir for batches\n");
        return 2;
    }
    if (!cli.output.empty() && !cli.outdir.empty()) {
        std::fprintf(stderr, "kikoe: use either -o/--output or --outdir, not both\n");
        return 2;
    }
    if (!cli.output.empty() && cli.formats.size() > 1) {
        std::fprintf(stderr, "kikoe: -o/--output accepts a single format; use --outdir for several\n");
        return 2;
    }

    // Resolve the model: explicit flag, or the small default.
    const std::string model_arg = cli.model.empty() ? "small" : cli.model;
    kikoe::ErrorCode err = kikoe::ErrorCode::Ok;
    const std::string model_path = kikoe::resolve_model(model_arg, err);
    if (model_path.empty()) {
        std::fprintf(stderr, "kikoe: model '%s' is not available (%s).\n",
                     model_arg.c_str(), kikoe::error_string(err));
        std::fprintf(stderr, "hint: kikoe --download-model %s\n", model_arg.c_str());
        return 2;
    }

    // VAD: ensure the silero model is present, downloading on first use.
    std::string vad_model_path;
    if (cli.vad) {
        const kikoe::ModelEntry* vad = kikoe::find_model("vad-silero");
        kikoe::ErrorCode verr = kikoe::ErrorCode::Ok;
        vad_model_path = kikoe::resolve_model("vad-silero", verr);
        if (vad_model_path.empty()) {
            std::fprintf(stderr, "kikoe: downloading the Silero VAD model (first --vad use)...\n");
            verr = kikoe::download_model(*vad, download_progress_cb, nullptr);
            std::fprintf(stderr, "\n");
            if (verr != kikoe::ErrorCode::Ok) {
                print_error(verr);
                return 3;
            }
            vad_model_path = kikoe::model_cache_dir() + "/ggml-silero-v6.2.0.bin";
        }
    }

    kikoe::EngineOptions eopts;
    eopts.model_path = model_path;
    eopts.n_threads = cli.threads;
    eopts.use_gpu = cli.gpu;

    err = kikoe::ErrorCode::Ok;
    auto engine = kikoe::Engine::create(eopts, err);
    if (!engine) {
        std::fprintf(stderr, "kikoe: could not load model '%s': %s\n",
                     model_path.c_str(), kikoe::error_string(err));
        return 2;
    }
    g_engine = engine.get();
    install_ctrl_handler();

    kikoe::TranscribeOptions topts;
    topts.language = cli.lang;
    topts.translate = cli.translate;
    topts.initial_prompt = cli.prompt;
    topts.vad = !vad_model_path.empty();
    topts.vad_model_path = vad_model_path;

    int failures = 0;
    const size_t n_inputs = cli.inputs.size();
    for (size_t fi = 0; fi < n_inputs; ++fi) {
        const std::string& input = cli.inputs[fi];
        std::string prefix;
        if (multiple_inputs) {
            char buf[64];
            std::snprintf(buf, sizeof buf, "[%zu/%zu] ", fi + 1, n_inputs);
            prefix = buf;
        }

        kikoe::PcmAudio audio;
        err = kikoe::load_pcm_any(input, audio);
        if (err != kikoe::ErrorCode::Ok) {
            std::fprintf(stderr, "%s%s: %s\n", prefix.c_str(), input.c_str(), kikoe::error_string(err));
            if (err == kikoe::ErrorCode::DecoderNotFound) {
                std::fprintf(stderr, "hint: install FFmpeg and make sure 'ffmpeg' is on PATH\n");
            }
            ++failures;
            continue;
        }

        kikoe::SegmentList segments;
        std::string cb_prefix = prefix.c_str();
        err = engine->transcribe(audio.samples.data(), audio.samples.size(), topts,
                                 progress_cb, nullptr,
                                 const_cast<char*>(cb_prefix.c_str()), &segments);
        std::fprintf(stderr, "\r%s      \r", prefix.c_str());
        if (err == kikoe::ErrorCode::Cancelled) {
            std::fprintf(stderr, "cancelled.\n");
            return 130;
        }
        if (err != kikoe::ErrorCode::Ok) {
            std::fprintf(stderr, "%s%s: %s\n", prefix.c_str(), input.c_str(), kikoe::error_string(err));
            ++failures;
            continue;
        }

        for (kikoe::OutputFormat fmt : cli.formats) {
            const std::string body = kikoe::format_segments(segments, fmt);
            const std::string ext = kikoe::format_extension(fmt);

            std::string target;
            if (!cli.output.empty()) target = cli.output;
            else if (!cli.outdir.empty()) target = join_path(cli.outdir, replace_extension(base_name(input), ext));
            else if (cli.formats.size() == 1 && !multiple_inputs) {
                std::fwrite(body.data(), 1, body.size(), stdout);
                continue;
            } else {
                target = replace_extension(input, ext);
            }

            std::ofstream f(target, std::ios::binary | std::ios::trunc);
            if (!f) {
                std::fprintf(stderr, "kikoe: cannot write '%s'\n", target.c_str());
                ++failures;
                continue;
            }
            f << body;
            std::fprintf(stderr, "%swrote %s\n", prefix.c_str(), target.c_str());
        }
    }

    return failures == 0 ? 0 : 4;
}
