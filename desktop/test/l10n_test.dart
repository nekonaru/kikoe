import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_desktop/src/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English is the source: t returns input unchanged', () async {
    await L10n.instance.setLocale('en');
    expect(L10n.instance.t('Cancel'), 'Cancel');
    expect(L10n.instance.t('Pick an audio or video file'), 'Pick an audio or video file');
  });

  test('Indonesian translates known keys and falls back for unknown', () async {
    await L10n.instance.setLocale('id');
    expect(L10n.instance.t('Cancel'), 'Batal');
    expect(L10n.instance.t('Share'), 'Bagikan');
    expect(L10n.instance.t('Some untranslated string'), 'Some untranslated string');
  });
}
