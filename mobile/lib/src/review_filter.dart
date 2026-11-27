/// Pure model and filter helpers for the transcript review screen.
library;

class ReviewWord {
  const ReviewWord(this.startMs, this.endMs, this.text);
  final int startMs;
  final int endMs;
  final String text;
}

class ReviewSegment {
  const ReviewSegment(
    this.startMs,
    this.endMs,
    this.text, {
    this.confidence = 0,
    this.speaker = 0,
    this.words = const [],
  });

  final int startMs;
  final int endMs;
  final String text;
  final int confidence; // permille, 0 when unavailable
  final int speaker;
  final List<ReviewWord> words;
}

enum ConfidenceBand { high, medium, low, unknown }

ConfidenceBand confidenceBand(int permille) {
  if (permille <= 0) return ConfidenceBand.unknown;
  if (permille >= 800) return ConfidenceBand.high;
  if (permille >= 600) return ConfidenceBand.medium;
  return ConfidenceBand.low;
}

/// Filter by text query, low-confidence segments and speaker index.
List<ReviewSegment> filterReview(
  List<ReviewSegment> segments, {
  String query = '',
  bool onlyLow = false,
  int? speaker,
}) {
  final needle = query.trim().toLowerCase();
  return segments.where((s) {
    if (needle.isNotEmpty &&
        !s.text.toLowerCase().contains(needle) &&
        !s.words.any((w) => w.text.toLowerCase().contains(needle))) {
      return false;
    }
    if (onlyLow && confidenceBand(s.confidence) != ConfidenceBand.low) return false;
    if (speaker != null && s.speaker != speaker) return false;
    return true;
  }).toList();
}
