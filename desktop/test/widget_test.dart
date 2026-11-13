import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_desktop/main.dart';

void main() {
  testWidgets('Kikoe home renders the header, controls and the drop hint', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const KikoeApp());
    await tester.pump();

    expect(find.text('Kikoe'), findsOneWidget);
    expect(find.text('Add files…'), findsOneWidget);
    // No model is cached in the test environment, so the start button
    // asks to download the model first.
    expect(find.text('Download the model first'), findsOneWidget);
    expect(find.textContaining('Drop audio or video files here'), findsOneWidget);
    expect(find.text('No files queued'), findsOneWidget);
  });
}
