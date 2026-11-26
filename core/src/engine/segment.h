#ifndef KIKOE_SEGMENT_H
#define KIKOE_SEGMENT_H

#include <cstdint>
#include <string>
#include <vector>

namespace kikoe {

// One word with its own timeline. Only populated when word timestamps are on.
struct Word {
    int64_t start_ms = 0;
    int64_t end_ms = 0;
    std::string text;
};

// One transcribed segment. Milliseconds align with the Whisper timeline.
struct Segment {
    int64_t start_ms = 0;
    int64_t end_ms = 0;
    std::string text;
    float confidence = 0.0f; // average token probability, 0 when unknown
    int speaker = 0;         // 0-based speaker index when diarization is on
    std::vector<Word> words; // empty unless word timestamps are requested
};

using SegmentList = std::vector<Segment>;

} // namespace kikoe

#endif // KIKOE_SEGMENT_H
