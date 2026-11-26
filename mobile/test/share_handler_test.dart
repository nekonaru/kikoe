import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_mobile/src/app_state.dart';
import 'package:kikoe_mobile/src/share_handler.dart';

class FakeAppState extends AppState {
  bool cachedOverride = true;
  final List<String> startedPaths = [];

  @override
  bool get selectedModelCached => cachedOverride;

  @override
  Future<void> transcribe() async {
    startedPaths.add(inputPath ?? '');
  }
}

void main() {
  test('share during startup is replayed once the engine is ready', () {
    final state = FakeAppState();
    final handler = ShareHandler(state);

    handler.handle(['a.wav']);
    expect(state.inputPath, 'a.wav');
    expect(state.startedPaths, isEmpty,
        reason: 'must not start before settings and model dir are loaded');

    handler.markStartupComplete();
    expect(state.startedPaths, ['a.wav']);
  });

  test('share after startup starts immediately', () {
    final state = FakeAppState();
    final handler = ShareHandler(state)..markStartupComplete();

    handler.handle(['b.wav']);
    expect(state.startedPaths, ['b.wav']);
  });

  test('share never auto-starts when the model is not cached', () {
    final state = FakeAppState()..cachedOverride = false;
    final handler = ShareHandler(state);

    handler.handle(['c.wav']);
    handler.markStartupComplete();

    expect(state.inputPath, 'c.wav');
    expect(state.startedPaths, isEmpty);
  });

  test('only the latest pending share is replayed', () {
    final state = FakeAppState();
    final handler = ShareHandler(state);

    handler.handle(['one.wav']);
    handler.handle(['two.wav']);
    handler.markStartupComplete();

    expect(state.startedPaths, ['two.wav']);
  });
}
