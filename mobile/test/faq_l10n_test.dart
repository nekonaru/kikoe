import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_mobile/src/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FAQ questions and answers are localized', () async {
    await L10n.instance.setLocale('en');
    expect(L10n.instance.t('What is Kikoe?'), 'What is Kikoe?');
    await L10n.instance.setLocale('id');
    expect(L10n.instance.t('What is Kikoe?'), 'Apa itu Kikoe?');
    expect(L10n.instance.t('Do I need an account or a subscription?'),
        'Apakah saya perlu akun atau langganan?');
    expect(L10n.instance.t('Unknown string stays as source'), 'Unknown string stays as source');
  });
}
