#include "formatter.h"

#include <cctype>
#include <cstdio>
#include <sstream>

namespace kikoe {

namespace {

std::string trim_copy(const std::string& s)
{
    size_t b = 0, e = s.size();
    while (b < e && std::isspace(static_cast<unsigned char>(s[b]))) ++b;
    while (e > b && std::isspace(static_cast<unsigned char>(s[e - 1]))) --e;
    return s.substr(b, e - b);
}

std::string timestamp(int64_t ms, char ms_sep)
{
    const int64_t total_s = ms / 1000;
    const int64_t hh = total_s / 3600;
    const int64_t mm = (total_s % 3600) / 60;
    const int64_t ss = total_s % 60;
    const int64_t mmm = ms % 1000;
    char buf[32];
    std::snprintf(buf, sizeof buf, "%02lld:%02lld:%02lld%c%03lld",
                  static_cast<long long>(hh),
                  static_cast<long long>(mm),
                  static_cast<long long>(ss),
                  ms_sep,
                  static_cast<long long>(mmm));
    return buf;
}

std::string json_escape(const std::string& s)
{
    std::string out;
    out.reserve(s.size() + 16);
    for (unsigned char c : s) {
        switch (c) {
        case '"':  out += "\\\""; break;
        case '\\': out += "\\\\"; break;
        case '\b': out += "\\b";  break;
        case '\f': out += "\\f";  break;
        case '\n': out += "\\n";  break;
        case '\r': out += "\\r";  break;
        case '\t': out += "\\t";  break;
        default:
            if (c < 0x20) {
                char buf[8];
                std::snprintf(buf, sizeof buf, "\\u%04x", c);
                out += buf;
            } else {
                out.push_back(static_cast<char>(c));
            }
        }
    }
    return out;
}

} // namespace

bool parse_format(const std::string& name, OutputFormat& out)
{
    std::string lower;
    lower.reserve(name.size());
    for (char c : name) lower.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));

    if (lower == "txt")  { out = OutputFormat::Txt;  return true; }
    if (lower == "srt")  { out = OutputFormat::Srt;  return true; }
    if (lower == "vtt")  { out = OutputFormat::Vtt;  return true; }
    if (lower == "json") { out = OutputFormat::Json; return true; }
    return false;
}

const char* format_extension(OutputFormat format)
{
    switch (format) {
    case OutputFormat::Txt:  return "txt";
    case OutputFormat::Srt:  return "srt";
    case OutputFormat::Vtt:  return "vtt";
    case OutputFormat::Json: return "json";
    }
    return "txt";
}

std::string format_segments(const SegmentList& segments, OutputFormat format)
{
    switch (format) {
    case OutputFormat::Txt: {
        std::string out;
        for (const auto& s : segments) {
            const std::string t = trim_copy(s.text);
            if (t.empty()) continue;
            out += t;
            out += '\n';
        }
        return out;
    }
    case OutputFormat::Srt: {
        std::ostringstream out;
        size_t i = 1;
        for (const auto& s : segments) {
            out << i++ << '\n';
            out << timestamp(s.start_ms, ',') << " --> " << timestamp(s.end_ms, ',') << '\n';
            out << trim_copy(s.text) << "\n\n";
        }
        return out.str();
    }
    case OutputFormat::Vtt: {
        std::ostringstream out;
        out << "WEBVTT\n\n";
        for (const auto& s : segments) {
            out << timestamp(s.start_ms, '.') << " --> " << timestamp(s.end_ms, '.') << '\n';
            out << trim_copy(s.text) << "\n\n";
        }
        return out.str();
    }
    case OutputFormat::Json: {
        std::ostringstream out;
        out << "{\n  \"segments\": [\n";
        for (size_t i = 0; i < segments.size(); ++i) {
            const auto& s = segments[i];
            out << "    {\"start_ms\": " << s.start_ms
                << ", \"end_ms\": " << s.end_ms
                << ", \"text\": \"" << json_escape(trim_copy(s.text)) << "\"}";
            if (i + 1 < segments.size()) out << ',';
            out << '\n';
        }
        out << "  ]\n}\n";
        return out.str();
    }
    }
    return {};
}

} // namespace kikoe
