import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_desktop/src/history_search.dart';

void main() {
  test('empty query matches every entry', () {
    expect(historyMatches('meeting.wav', 'hello world', ''), isTrue);
    expect(historyMatches('meeting.wav', 'hello world', '   '), isTrue);
  });

  test('matches file name regardless of case', () {
    expect(historyMatches('Meeting.WAV', 'nothing here', 'meeting'), isTrue);
  });

  test('matches transcript text regardless of case', () {
    expect(historyMatches('take.wav', 'And so my fellow Americans', 'AMERICANS'), isTrue);
  });

  test('rejects a query that matches neither field', () {
    expect(historyMatches('meeting.wav', 'hello world', 'budget'), isFalse);
  });
}
