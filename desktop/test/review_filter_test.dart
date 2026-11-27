import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_desktop/src/review_filter.dart';

void main() {
  test('confidence bands use fixed thresholds', () {
    expect(confidenceBand(0), ConfidenceBand.unknown);
    expect(confidenceBand(450), ConfidenceBand.low);
    expect(confidenceBand(700), ConfidenceBand.medium);
    expect(confidenceBand(900), ConfidenceBand.high);
  });

  test('query matches segment text and individual words', () {
    final segments = [
      ReviewSegment(0, 1000, 'hello world',
          words: const [ReviewWord(0, 100, 'hello')]),
      ReviewSegment(1000, 2000, 'goodbye'),
    ];
    expect(filterReview(segments, query: 'WORLD').length, 1);
    expect(filterReview(segments, query: 'hello').length, 1);
    expect(filterReview(segments, query: 'missing'), isEmpty);
  });

  test('low confidence and speaker filters combine', () {
    final segments = [
      ReviewSegment(0, 1000, 'one', confidence: 400, speaker: 0),
      ReviewSegment(1000, 2000, 'two', confidence: 900, speaker: 0),
      ReviewSegment(2000, 3000, 'three', confidence: 500, speaker: 1),
    ];
    expect(filterReview(segments, onlyLow: true).length, 2);
    expect(filterReview(segments, onlyLow: true, speaker: 0).length, 1);
    expect(filterReview(segments, speaker: 1).single.text, 'three');
  });
}
