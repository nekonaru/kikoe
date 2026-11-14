/// Runs Kikoe engine work (transcription) in a background isolate.
///
/// The worker owns the native engine (kk_engine*). Media is decoded by the
/// platform before reaching this point (see MainActivity.kt, MediaCodec);
/// the worker receives mono 16 kHz float32 PCM and never touches files.
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'kikoe_ffi.dart';

sealed class TranscriberEvent {
  const TranscriberEvent();
}

class Ready extends TranscriberEvent {
  const Ready(this.abiVersion);
  final int abiVersion;
}

class TranscribeProgress extends TranscriberEvent {
  const TranscribeProgress(this.id, this.percent);
  final String id;
  final int percent;
}

class SegmentReady extends TranscriberEvent {
  const SegmentReady(this.id, this.startMs, this.endMs, this.text);
  final String id;
  final int startMs;
  final int endMs;
  final String text;
}

class TranscribeDone extends TranscriberEvent {
  const TranscribeDone(this.id);
  final String id;
}

class TranscribeFailed extends TranscriberEvent {
  const TranscribeFailed(this.id, this.message, {this.cancelled = false});
  final String id;
  final String message;
  final bool cancelled;
}

class FormatResult extends TranscriberEvent {
  const FormatResult(this.id, this.format, this.content);
  final String id;
  final String format;
  final String content;
}

class Transcriber {
  Isolate? _isolate;
  SendPort? _port;
  ReceivePort? _eventsRecv;
  final _events = StreamController<TranscriberEvent>.broadcast();

  Stream<TranscriberEvent> get events => _events.stream;

  Future<void> start() async {
    if (_isolate != null) return;

    _eventsRecv = ReceivePort();
    _eventsRecv!.listen((dynamic raw) {
      if (raw is! Map) return;
      final event = _eventFromMap(Map<String, dynamic>.from(raw));
      if (event != null) _events.add(event);
    });

    final ready = ReceivePort();
    _isolate = await Isolate.spawn(
      _workerMain,
      ready.sendPort,
      debugName: 'kikoe-worker',
    );
    _port = await ready.first as SendPort;
    ready.close();

    _port!.send({'type': 'init', 'eventsPort': _eventsRecv!.sendPort});
  }

  void dispose() {
    _port?.send({'type': 'shutdown'});
    _eventsRecv?.close();
    _events.close();
    _port = null;
    _isolate = null;
    _eventsRecv = null;
  }

  /// Transcribe mono 16 kHz float32 PCM. [id] correlates events.
  void transcribePcm({
    required String id,
    required Float32List samples,
    required String modelPath,
    String language = 'auto',
    bool translate = false,
    String initialPrompt = '',
    int nThreads = 0,
  }) {
    _send({
      'type': 'transcribePcm',
      'id': id,
      'samples': samples,
      'modelPath': modelPath,
      'language': language,
      'translate': translate,
      'initialPrompt': initialPrompt,
      'nThreads': nThreads,
    });
  }

  void cancel() => _send({'type': 'cancel'});

  void formatLast(String id, String format) =>
      _send({'type': 'format', 'id': id, 'format': format});

  void _send(Map<String, dynamic> message) {
    final port = _port;
    if (port == null) {
      throw StateError('Transcriber not started; call start() first');
    }
    port.send(message);
  }
}

TranscriberEvent? _eventFromMap(Map<String, dynamic> map) {
  switch (map['type']) {
    case 'ready':
      return Ready(map['abiVersion'] as int);
    case 'transcribeProgress':
      return TranscribeProgress(map['id'] as String, map['percent'] as int);
    case 'segment':
      return SegmentReady(
        map['id'] as String,
        map['startMs'] as int,
        map['endMs'] as int,
        map['text'] as String,
      );
    case 'transcribeDone':
      return TranscribeDone(map['id'] as String);
    case 'transcribeFailed':
      return TranscribeFailed(
        map['id'] as String,
        map['message'] as String,
        cancelled: map['cancelled'] as bool? ?? false,
      );
    case 'formatResult':
      return FormatResult(map['id'] as String, map['format'] as String, map['content'] as String);
  }
  return null;
}

class _ForeignError implements Exception {
  const _ForeignError(this.message);
  final String message;
  @override
  String toString() => message;
}

void _workerMain(SendPort readyPort) {
  final recv = ReceivePort();
  readyPort.send(recv.sendPort);

  KikoeFFI? ffi;
  String? ffiError;
  try {
    ffi = KikoeFFI.load();
  } catch (e) {
    ffiError = e.toString();
  }

  Pointer<Void> engine = nullptr;
  String? engineModelPath;
  int engineThreads = 0;
  SendPort? events;

  void emit(Map<String, dynamic> map) => events?.send(map);

  void ensureEngine(String modelPath, int nThreads) {
    final lib = ffi;
    if (lib == null) throw const _ForeignError('FFI library is not loaded');
    if (engine != nullptr && engineModelPath == modelPath && engineThreads == nThreads) {
      return;
    }
    if (engine != nullptr) {
      lib.engineFree(engine);
      engine = nullptr;
    }
    final params = calloc<KkEngineParams>();
    params.ref.modelPath = modelPath.toNativeUtf8();
    params.ref.nThreads = nThreads;
    params.ref.useGpu = 0; // CPU is the tested path on Android
    params.ref.vad = 0;
    params.ref.vadModelPath = nullptr;
    final err = calloc<Int32>();
    engine = lib.engineCreate(params, err);
    final code = err.value;
    calloc.free(err);
    calloc.free(params.ref.modelPath);
    calloc.free(params);
    if (engine == nullptr || code != kKkOk) {
      throw _ForeignError('engine create failed: ${lib.describeError(code)}');
    }
    engineModelPath = modelPath;
    engineThreads = nThreads;
  }

  recv.listen((dynamic raw) {
    if (raw is! Map) return;
    final msg = Map<String, dynamic>.from(raw);
    switch (msg['type']) {
      case 'init':
        events = msg['eventsPort'] as SendPort;
        if (ffi == null) {
          emit({'type': 'transcribeFailed', 'id': '', 'message': ffiError ?? 'FFI library failed to load', 'cancelled': false});
          break;
        }
        emit({'type': 'ready', 'abiVersion': ffi.abiVersion});
        break;
      case 'shutdown':
        if (engine != nullptr) ffi?.engineFree(engine);
        Isolate.exit();
      case 'cancel':
        if (engine != nullptr) ffi?.cancel(engine);
        break;
      case 'transcribePcm':
        final String id = msg['id'] as String;
        if (ffi == null) {
          emit({'type': 'transcribeFailed', 'id': id, 'message': ffiError ?? 'FFI library failed to load', 'cancelled': false});
          break;
        }
        final lib = ffi;
        try {
          ensureEngine(msg['modelPath'] as String, msg['nThreads'] as int);
        } on _ForeignError catch (e) {
          emit({'type': 'transcribeFailed', 'id': id, 'message': e.message, 'cancelled': false});
          break;
        }

        final Float32List samples = msg['samples'] as Float32List;
        final samplesPtr = calloc<Float>(samples.length);
        samplesPtr.asTypedList(samples.length).setAll(0, samples);

        final language = (msg['language'] as String).toNativeUtf8();
        final promptText = msg['initialPrompt'] as String;
        final promptPtr = promptText.isEmpty ? nullptr : promptText.toNativeUtf8();
        final options = calloc<KkOptions>();
        options.ref.language = language;
        options.ref.translate = (msg['translate'] as bool) ? 1 : 0;
        options.ref.initialPrompt = promptPtr;

        final rc = lib.transcribePcm(
          engine,
          samplesPtr,
          samples.length,
          options,
          nullptr,  // progress: reported post-hoc, not through FFI callbacks
          nullptr,  // segment callbacks: harvested after the call returns
          nullptr,
        );

        calloc.free(options);
        calloc.free(language);
        if (promptPtr != nullptr) calloc.free(promptPtr);
        calloc.free(samplesPtr);

        if (rc == kKkOk) {
          // Harvest segments from the engine after the blocking FFI call returns.
          final count = lib.lastSegmentCount(engine);
          for (var i = 0; i < count; i++) {
            final src = calloc<KkSegment>();
            if (lib.lastSegmentGet(engine, i, src) == kKkOk) {
              emit({
                'type': 'segment',
                'id': id,
                'startMs': src.ref.startMs,
                'endMs': src.ref.endMs,
                'text': src.ref.text.toDartString(),
              });
            }
            calloc.free(src);
          }
          emit({'type': 'transcribeDone', 'id': id});
        } else if (rc == kKkErrCancelled) {
          emit({'type': 'transcribeFailed', 'id': id, 'message': 'cancelled', 'cancelled': true});
        } else {
          emit({'type': 'transcribeFailed', 'id': id, 'message': lib.describeError(rc), 'cancelled': false});
        }
        break;
      case 'format':
        final String id = msg['id'] as String;
        final String format = msg['format'] as String;
        final lib = ffi;
        if (lib == null || engine == nullptr) {
          emit({'type': 'formatResult', 'id': id, 'format': format, 'content': ''});
          break;
        }
        final formatPtr = format.toNativeUtf8();
        final written = calloc<Uint64>();
        lib.formatLast(engine, formatPtr, nullptr, 0, written);
        final need = written.value;
        if (need == 0) {
          calloc.free(formatPtr);
          calloc.free(written);
          emit({'type': 'formatResult', 'id': id, 'format': format, 'content': ''});
          break;
        }
        final buf = calloc<Uint8>(need);
        lib.formatLast(engine, formatPtr, buf.cast<Utf8>(), need, written);
        final content = buf.cast<Utf8>().toDartString();
        calloc.free(buf);
        calloc.free(formatPtr);
        calloc.free(written);
        emit({'type': 'formatResult', 'id': id, 'format': format, 'content': content});
        break;
    }
  });
}
