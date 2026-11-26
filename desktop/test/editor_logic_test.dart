import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_desktop/src/transcript_editor_logic.dart';

void main() {
  test('replaceAll replaces across segments and respects case', () {
    final texts = ['Hello world', 'hello again', 'nothing'];
    final changed = replaceAcross(texts, 'hello', 'hi', caseSensitive: false);
    expect(changed, 2);
    expect(texts, ['hi world', 'hi again', 'nothing']);
  });

  test('replaceAll with case sensitivity only touches exact match', () {
    final texts = ['Hello world', 'hello again'];
    final changed = replaceAcross(texts, 'hello', 'hi', caseSensitive: true);
    expect(changed, 1);
    expect(texts, ['Hello world', 'hi again']);
  });

  test('shiftTiming never produces negative timestamps', () {
    final starts = [0, 1000, 5000];
    final ends = [900, 2000, 6000];
    shiftTiming(starts, ends, -1500);
    expect(starts, [0, 0, 3500]);
    expect(ends, [0, 500, 4500]);
  });
}
