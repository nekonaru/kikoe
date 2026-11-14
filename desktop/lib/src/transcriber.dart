/// Runs Kikoe engine work (transcription, model downloads) in a background
/// isolate and exposes typed events to the UI.
///
/// The worker owns the native engine (kk_engine*) so the UI never touches the
/// FFI layer and stays responsive during long jobs.
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'kikoe_ffi.dart';

/// Events emitted by the worker isolate.
sealed class TranscriberEvent {
  const TranscriberEvent();
}

class Ready extends TranscriberEvent {
  const Ready(this.abiVersion, this.cacheDir);
  final int abiVersion;
  final String cacheDir;
}

class FfiError extends TranscriberEvent {
  const FfiError(this.message);
  final String message;
}

class DownloadDone extends TranscriberEvent {
  const DownloadDone(this.name);
  final String name;
}

class DownloadFailed extends TranscriberEvent {
  const DownloadFailed(this.name, this.message);
  final String name;
  final String message;
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

  /// Spawn the worker and wait for it to report ready.
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

  /// Transcribe [mediaPath]. [id] is a caller-chosen correlation id.
  void transcribe({
    required String id,
    required String mediaPath,
    required String modelPath,
    String language = 'auto',
    bool translate = false,
    String initialPrompt = '',
    int nThreads = 0,
    bool useGpu = false,
  }) {
    _send({
      'type': 'transcribe',
      'id': id,
      'mediaPath': mediaPath,
      'modelPath': modelPath,
      'language': language,
      'translate': translate,
      'initialPrompt': initialPrompt,
      'nThreads': nThreads,
      'useGpu': useGpu,
    });
  }

  /// Cancel the in-flight transcription (no-op when idle).
  void cancel() => _send({'type': 'cancel'});

  /// Download a registry model by name, verifying its SHA-256.
  void downloadModel(String name) => _send({'type': 'download', 'name': name});

  /// Render the last transcription of [id] as [format] ("txt", "srt", "vtt",
  /// "json"); the result arrives as [FormatResult].
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
      return Ready(map['abiVersion'] as int, map['cacheDir'] as String);
    case 'ffiError':
      return FfiError(map['message'] as String);
    case 'downloadDone':
      return DownloadDone(map['name'] as String);
    case 'downloadFailed':
      return DownloadFailed(map['name'] as String, map['message'] as String);
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

// ---------------------------------------------------------------------------
// Worker isolate. Owns the native process; never touches the UI.
// ---------------------------------------------------------------------------

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
    ffiError = e.toString().replaceFirst('Invalid argument(s): ', '');
  }

  Pointer<Void> engine = nullptr;
  String? engineModelPath;
  bool engineUseGpu = false;
  int engineThreads = 0;
  SendPort? events;

  void emit(Map<String, dynamic> map) => events?.send(map);

  void ensureEngine(String modelPath, int nThreads, bool useGpu) {
    final lib = ffi;
    if (lib == null) throw const _ForeignError('FFI library is not loaded');
    if (engine != nullptr &&
        engineModelPath == modelPath &&
        engineThreads == nThreads &&
        engineUseGpu == useGpu) {
      return;
    }
    if (engine != nullptr) {
      lib.engineFree(engine);
      engine = nullptr;
    }
    final params = calloc<KkEngineParams>();
    params.ref.modelPath = modelPath.toNativeUtf8();
    params.ref.nThreads = nThreads;
    params.ref.useGpu = useGpu ? 1 : 0;
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
    engineUseGpu = useGpu;
  }

  recv.listen((dynamic raw) {
    if (raw is! Map) return;
    final msg = Map<String, dynamic>.from(raw);
    switch (msg['type']) {
      case 'init':
        events = msg['eventsPort'] as SendPort;
        final lib = ffi;
        if (lib == null) {
          emit({'type': 'ffiError', 'message': ffiError ?? 'unknown FFI error'});
          break;
        }
        final cacheDirPtr = lib.modelCacheDir();
        emit({
          'type': 'ready',
          'abiVersion': lib.abiVersion,
          'cacheDir': cacheDirPtr == nullptr ? '' : cacheDirPtr.toDartString(),
        });
        break;
      case 'shutdown':
        if (engine != nullptr) ffi?.engineFree(engine);
        Isolate.exit();
      case 'cancel':
        if (engine != nullptr) ffi?.cancel(engine);
        break;
      case 'download':
        final name = msg['name'] as String;
        final lib = ffi;
        if (lib == null) {
          emit({'type': 'downloadFailed', 'name': name, 'message': ffiError ?? 'FFI library is not loaded'});
          break;
        }
        final namePtr = name.toNativeUtf8();
        // Progress is not reported through FFI callbacks; the call is
        // synchronous and the UI shows an indeterminate state.
        final rc = lib.downloadModel(namePtr, nullptr, nullptr);
        calloc.free(namePtr);
        if (rc == kKkOk) {
          emit({'type': 'downloadDone', 'name': name});
        } else {
          emit({'type': 'downloadFailed', 'name': name, 'message': lib.describeError(rc)});
        }
        break;
      case 'transcribe':
        final String id = msg['id'] as String;
        if (ffi == null) {
          emit({'type': 'transcribeFailed', 'id': id, 'message': ffiError ?? 'FFI library is not loaded', 'cancelled': false});
          break;
        }
        try {
          ensureEngine(
            msg['modelPath'] as String,
            msg['nThreads'] as int,
            msg['useGpu'] as bool,
          );
        } on _ForeignError catch (e) {
          emit({'type': 'transcribeFailed', 'id': id, 'message': e.message, 'cancelled': false});
          return;
        }
        final lib = ffi;
        final mediaPath = (msg['mediaPath'] as String).toNativeUtf8();
        final language = (msg['language'] as String).toNativeUtf8();
        final promptText = msg['initialPrompt'] as String;
        final promptPtr = promptText.isEmpty ? nullptr : promptText.toNativeUtf8();
        final options = calloc<KkOptions>();
        options.ref.language = language;
        options.ref.translate = (msg['translate'] as bool) ? 1 : 0;
        options.ref.initialPrompt = promptPtr;

        final rc = lib.transcribe(
          engine,
          mediaPath,
          options,
          nullptr,  // progress: not through FFI callbacks; the UI is indeterminate
          nullptr,  // segment callbacks: harvested after the call returns
          nullptr,
        );

        calloc.free(options);
        calloc.free(mediaPath);
        calloc.free(language);
        if (promptPtr != nullptr) calloc.free(promptPtr);

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
