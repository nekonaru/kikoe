/// Pure operations behind the transcript editor.
///
/// Kept out of the widget so timing and text changes can be unit tested.
library;

class SegmentEntry {
  SegmentEntry(this.startMs, this.endMs, this.text);
  int startMs;
  int endMs;
  String text;
}

/// Split [segment] at [atMs], clamped to its own range.
/// The original keeps the left half; the returned segment holds the right half.
SegmentEntry splitSegment(SegmentEntry segment, int atMs) {
  final point = atMs < segment.startMs
      ? segment.startMs
      : atMs > segment.endMs
          ? segment.endMs
          : atMs;
  final right = SegmentEntry(point, segment.endMs, segment.text);
  segment.endMs = point;
  return right;
}

/// Merge [second] into [first] and return true when a merge happened.
bool mergeSegments(List<SegmentEntry> segments, int index) {
  if (index < 0 || index + 1 >= segments.length) return false;
  final first = segments[index];
  final second = segments[index + 1];
  first.endMs = second.endMs;
  first.text = '${first.text}${second.text}';
  segments.removeAt(index + 1);
  return true;
}

/// Remove consecutive duplicate words, a common Whisper hallucination.
String cleanRepeatedWords(String text) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length < 2) return text.trim();
  final out = <String>[words.first];
  for (var i = 1; i < words.length; i++) {
    final current = words[i].toLowerCase().replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
    final previous = out.last.toLowerCase().replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
    if (current.isNotEmpty && current == previous) continue;
    out.add(words[i]);
  }
  return out.join(' ');
}

/// Apply [cleanRepeatedWords] to every segment. Returns how many changed.
int cleanupSegments(List<SegmentEntry> segments) {
  var changed = 0;
  for (final segment in segments) {
    final cleaned = cleanRepeatedWords(segment.text);
    if (cleaned != segment.text) {
      segment.text = cleaned;
      changed++;
    }
  }
  return changed;
}
