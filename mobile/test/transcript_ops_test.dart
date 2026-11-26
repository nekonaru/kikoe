import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_mobile/src/transcript_ops.dart';

void main() {
  test('split keeps left half and returns right half', () {
    final seg = SegmentEntry(1000, 5000, 'hello world');
    final right = splitSegment(seg, 3000);
    expect(seg.endMs, 3000);
    expect(right.startMs, 3000);
    expect(right.endMs, 5000);
  });

  test('split clamps outside the segment range', () {
    final seg = SegmentEntry(1000, 2000, 'hello');
    expect(splitSegment(seg, 0).startMs, 1000);
    expect(seg.endMs, 1000);
  });

  test('merge joins text and timing', () {
    final segments = [
      SegmentEntry(0, 1000, 'hello '),
      SegmentEntry(1000, 2000, 'world'),
    ];
    expect(mergeSegments(segments, 0), isTrue);
    expect(segments.length, 1);
    expect(segments.single.endMs, 2000);
    expect(segments.single.text, 'hello world');
  });

  test('merge is a no-op at the edges', () {
    final segments = [SegmentEntry(0, 1000, 'only')];
    expect(mergeSegments(segments, 0), isFalse);
    expect(mergeSegments(segments, 5), isFalse);
  });

  test('cleanup removes repeated words but keeps distinct ones', () {
    expect(cleanRepeatedWords('no no thank you'), 'no thank you');
    expect(cleanRepeatedWords('hello hello world world'), 'hello world');
    expect(cleanRepeatedWords('one two three'), 'one two three');
  });

  test('cleanupSegments reports how many segments changed', () {
    final segments = [
      SegmentEntry(0, 1000, 'the the answer'),
      SegmentEntry(1000, 2000, 'fine'),
    ];
    expect(cleanupSegments(segments), 1);
    expect(segments.first.text, 'the answer');
  });
}
