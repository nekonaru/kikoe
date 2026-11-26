import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:kikoe_mobile/src/app_state.dart';
import 'package:kikoe_mobile/src/transcriber.dart';

class FakeTranscriber extends Transcriber {
  final controller = StreamController<TranscriberEvent>.broadcast();

  @override
  Stream<TranscriberEvent> get events => controller.stream;

  @override
  Future<void> start() async {}

  @override
  void transcribePcm({
    required String id,
    required Float32List samples,
    required String modelPath,
    String language = 'auto',
    bool translate = false,
    String initialPrompt = '',
    int nThreads = 0,
    String? vadModelPath,
    int quality = 0,
    bool wordTimestamps = false,
    bool diarize = false,
  }) {}

  @override
  void cancel() {}

  @override
  void dispose() {}
}

void main() {
  test('segments from a stale job are ignored', () async {
    final transcriber = FakeTranscriber();
    final state = AppState(transcriber: transcriber);
    state.setInput('a.wav');
    state.activeJobId = 'current';

    transcriber.controller.add(const SegmentReady('stale', 0, 1000, 'old text'));
    await pumpEventQueue();
    expect(state.segments, isEmpty);

    transcriber.controller.add(const SegmentReady('current', 0, 1000, 'new text'));
    await pumpEventQueue();
    expect(state.segments.map((s) => s.text), ['new text']);
  });

  test('stale done does not finish the current job', () async {
    final transcriber = FakeTranscriber();
    final state = AppState(transcriber: transcriber);
    state.activeJobId = 'current';
    state.stage = JobStage.transcribing;

    transcriber.controller.add(const TranscribeDone('stale'));
    await pumpEventQueue();
    expect(state.stage, JobStage.transcribing);

    transcriber.controller.add(const TranscribeDone('current'));
    await pumpEventQueue();
    expect(state.stage, JobStage.done);
  });

  test('progress reported before transcribing is ignored', () async {
    final transcriber = FakeTranscriber();
    final state = AppState(transcriber: transcriber);
    state.activeJobId = 'current';
    state.stage = JobStage.decoding;
    state.progress = 0;

    transcriber.controller.add(const TranscribeProgress('current', 100));
    await pumpEventQueue();
    expect(state.progress, 0);
  });

  test('stale progress does not overwrite current progress', () async {
    final transcriber = FakeTranscriber();
    final state = AppState(transcriber: transcriber);
    state.activeJobId = 'current';
    state.stage = JobStage.transcribing;
    state.progress = 40;

    transcriber.controller.add(const TranscribeProgress('stale', 95));
    await pumpEventQueue();
    expect(state.progress, 40);

    transcriber.controller.add(const TranscribeProgress('current', 55));
    await pumpEventQueue();
    expect(state.progress, 55);
  });
}
