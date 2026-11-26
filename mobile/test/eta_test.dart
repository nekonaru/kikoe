import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_mobile/src/eta.dart';

void main() {
  test('no estimate before enough progress or time', () {
    expect(estimateRemainingMs(500, 10), isNull);
    expect(estimateRemainingMs(5000, 4), isNull);
    expect(estimateRemainingMs(5000, 100), isNull);
  });

  test('estimate scales linearly from observed rate', () {
    // 10 seconds for 20 percent means about 40 seconds remaining.
    expect(estimateRemainingMs(10000, 20), 40000);
    expect(estimateRemainingMs(30000, 60), 20000);
  });

  test('smoothing damps a sudden jump', () {
    expect(smoothEtaMs(null, 40000), 40000);
    expect(smoothEtaMs(40000, 80000), 50000);
  });

  test('compact label is language neutral', () {
    expect(formatEtaLabel(12000), '~12s');
    expect(formatEtaLabel(125000), '~2m 05s');
  });
}
