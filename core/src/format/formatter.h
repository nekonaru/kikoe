#ifndef KIKOE_FORMATTER_H
#define KIKOE_FORMATTER_H

#include "../engine/segment.h"

#include <string>

namespace kikoe {

enum class OutputFormat {
    Txt,
    Srt,
    Vtt,
    Json,
};

// Parse a CLI format name: "txt", "srt", "vtt", "json" (case insensitive).
// Returns false for anything else.
bool parse_format(const std::string& name, OutputFormat& out);

const char* format_extension(OutputFormat format);

// Render segments as TXT, SRT, VTT or JSON. Always returns valid file content;
// never fails. JSON escapes all control characters per RFC 8259.
std::string format_segments(const SegmentList& segments, OutputFormat format);

} // namespace kikoe

#endif // KIKOE_FORMATTER_H
