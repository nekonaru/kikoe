import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_mobile/main.dart';

void main() {
  testWidgets('Kikoe home renders picker card and model section', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const KikoeApp());
    await tester.pump();

    expect(find.text('Kikoe'), findsOneWidget);
    expect(find.textContaining('Pick an audio or video file'), findsOneWidget);
    expect(find.text('MODEL'), findsOneWidget);
    expect(find.text('OPTIONS'), findsOneWidget);
    expect(find.text('Pick a file first'), findsOneWidget);
  });
}
