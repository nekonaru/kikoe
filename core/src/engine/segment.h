#ifndef KIKOE_SEGMENT_H
#define KIKOE_SEGMENT_H

#include <cstdint>
#include <string>
#include <vector>

namespace kikoe {

// One transcribed segment. Milliseconds align with the Whisper timeline.
struct Segment {
    int64_t start_ms = 0;
    int64_t end_ms = 0;
    std::string text;
};

using SegmentList = std::vector<Segment>;

} // namespace kikoe

#endif // KIKOE_SEGMENT_H
