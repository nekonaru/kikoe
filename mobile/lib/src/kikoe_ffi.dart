/// FFI bindings to the Kikoe C API (core/include/kikoe.h), Android edition.
///
/// Loads libkikoe_ffi.so from the application's jniLib directory. See the
/// desktop bindings for the semantics of each function; the contract is the
/// same one the C contract test exercises.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

const int kKkOk = 0;
const int kKkErrIo = 1;
const int kKkErrInvalidMedia = 2;
const int kKkErrUnsupportedFormat = 3;
const int kKkErrDecoderFailed = 4;
const int kKkErrDecoderNotFound = 5;
const int kKkErrModelNotFound = 6;
const int kKkErrModelChecksum = 7;
const int kKkErrCancelled = 8;
const int kKkErrOutOfMemory = 9;
const int kKkErrEngine = 10;
const int kKkErrInvalidArgument = 11;

typedef KKEngineCreateNative = Pointer<Void> Function(
    Pointer<KkEngineParams> params, Pointer<Int32> err);
typedef KKEngineCreate = Pointer<Void> Function(
    Pointer<KkEngineParams> params, Pointer<Int32> err);

typedef KKTranscribeNative = Int32 Function(
    Pointer<Void> engine,
    Pointer<Utf8> mediaPath,
    Pointer<KkOptions> options,
    Pointer<NativeFunction<KkProgressCb>> onProgress,
    Pointer<NativeFunction<KkSegmentCb>> onSegment,
    Pointer<Void> user);
typedef KKTranscribe = int Function(
    Pointer<Void> engine,
    Pointer<Utf8> mediaPath,
    Pointer<KkOptions> options,
    Pointer<NativeFunction<KkProgressCb>> onProgress,
    Pointer<NativeFunction<KkSegmentCb>> onSegment,
    Pointer<Void> user);

typedef KKTranscribePcmNative = Int32 Function(
    Pointer<Void> engine,
    Pointer<Float> samples,
    Uint64 nSamples,
    Pointer<KkOptions> options,
    Pointer<NativeFunction<KkProgressCb>> onProgress,
    Pointer<NativeFunction<KkSegmentCb>> onSegment,
    Pointer<Void> user);
typedef KKTranscribePcm = int Function(
    Pointer<Void> engine,
    Pointer<Float> samples,
    int nSamples,
    Pointer<KkOptions> options,
    Pointer<NativeFunction<KkProgressCb>> onProgress,
    Pointer<NativeFunction<KkSegmentCb>> onSegment,
    Pointer<Void> user);

typedef KKCancelNative = Void Function(Pointer<Void> engine);
typedef KKCancel = void Function(Pointer<Void> engine);

typedef KKLastProgressNative = Int32 Function(Pointer<Void> engine);
typedef KKLastProgress = int Function(Pointer<Void> engine);

typedef KKLastSegmentCountNative = Int32 Function(Pointer<Void> engine);
typedef KKLastSegmentCount = int Function(Pointer<Void> engine);

typedef KKLastSegmentGetNative = Int32 Function(
    Pointer<Void> engine, Int32 index, Pointer<KkSegment> outSegment);
typedef KKLastSegmentGet = int Function(
    Pointer<Void> engine, int index, Pointer<KkSegment> outSegment);

typedef KKLastSegmentConfidenceNative = Int32 Function(Pointer<Void> engine, Int32 index);
typedef KKLastSegmentConfidence = int Function(Pointer<Void> engine, int index);

typedef KKLastSegmentSpeakerNative = Int32 Function(Pointer<Void> engine, Int32 index);
typedef KKLastSegmentSpeaker = int Function(Pointer<Void> engine, int index);

typedef KKLastWordCountNative = Int32 Function(Pointer<Void> engine, Int32 index);
typedef KKLastWordCount = int Function(Pointer<Void> engine, int index);

typedef KKLastWordGetNative = Int32 Function(
    Pointer<Void> engine, Int32 index, Int32 wordIndex, Pointer<KkWord> outWord);
typedef KKLastWordGet = int Function(
    Pointer<Void> engine, int index, int wordIndex, Pointer<KkWord> outWord);

typedef KKFormatLastNative = Int32 Function(
    Pointer<Void> engine,
    Pointer<Utf8> format,
    Pointer<Utf8> outBuffer,
    Uint64 bufferSize,
    Pointer<Uint64> outWritten);
typedef KKFormatLast = int Function(
    Pointer<Void> engine,
    Pointer<Utf8> format,
    Pointer<Utf8> outBuffer,
    int bufferSize,
    Pointer<Uint64> outWritten);

typedef KKEngineFreeNative = Void Function(Pointer<Void> engine);
typedef KKEngineFree = void Function(Pointer<Void> engine);

typedef KKAbiVersionNative = Int32 Function();
typedef KKAbiVersion = int Function();

typedef KKGpuEnabledNative = Int32 Function();
typedef KKGpuEnabled = int Function();

typedef KKVersionStringNative = Pointer<Utf8> Function();
typedef KKVersionString = Pointer<Utf8> Function();

typedef KKErrorStringNative = Pointer<Utf8> Function(Int32 err);
typedef KKErrorString = Pointer<Utf8> Function(int err);

typedef KkProgressCb = Void Function(Int32 percent, Pointer<Void> user);
typedef KkSegmentCb = Void Function(Pointer<KkSegment> seg, Pointer<Void> user);

/// Mirrors struct kk_engine_params from core/include/kikoe.h exactly.
final class KkEngineParams extends Struct {
  external Pointer<Utf8> modelPath;
  @Int32()
  external int nThreads;
  @Int32()
  external int useGpu;
  @Int32()
  external int vad;
  external Pointer<Utf8> vadModelPath;
}

/// Mirrors struct kk_options from core/include/kikoe.h.
final class KkOptions extends Struct {
  external Pointer<Utf8> language;
  @Int32()
  external int translate;
  external Pointer<Utf8> initialPrompt;
  @Int32()
  external int quality; // 0 balanced, 1 fast, 2 accurate
  @Int32()
  external int wordTimestamps;
  @Int32()
  external int diarize;
}

/// Mirrors struct kk_word from core/include/kikoe.h.
final class KkWord extends Struct {
  @Int64()
  external int startMs;
  @Int64()
  external int endMs;
  external Pointer<Utf8> text;
}

/// Mirrors struct kk_segment from core/include/kikoe.h.
final class KkSegment extends Struct {
  @Int64()
  external int startMs;
  @Int64()
  external int endMs;
  external Pointer<Utf8> text;
}

DynamicLibrary _loadLibrary() {
  final envPath = Platform.environment['KIKOE_FFI_PATH'];
  if (envPath != null && envPath.isNotEmpty && File(envPath).existsSync()) {
    return DynamicLibrary.open(envPath);
  }
  if (Platform.isAndroid) {
    // Packaged in the APK under lib/<abi>/libkikoe_ffi.so (jniLibs).
    return DynamicLibrary.open('libkikoe_ffi.so');
  }
  throw UnsupportedError('Kikoe FFI is packaged for Android only in this build');
}

class KikoeFFI {
  KikoeFFI._(this._lib) {
    abiVersion = _lib.lookupFunction<KKAbiVersionNative, KKAbiVersion>('kk_abi_version')();
    gpuEnabled = _lib.lookupFunction<KKGpuEnabledNative, KKGpuEnabled>('kk_gpu_enabled')();
        versionString =
        _lib.lookupFunction<KKVersionStringNative, KKVersionString>('kk_version_string')().toDartString();
    engineCreate = _lib.lookupFunction<KKEngineCreateNative, KKEngineCreate>('kk_engine_create');
    transcribe = _lib.lookupFunction<KKTranscribeNative, KKTranscribe>('kk_transcribe');
    transcribePcm = _lib.lookupFunction<KKTranscribePcmNative, KKTranscribePcm>('kk_transcribe_pcm');
    cancel = _lib.lookupFunction<KKCancelNative, KKCancel>('kk_cancel');
    lastProgress = _lib.lookupFunction<KKLastProgressNative, KKLastProgress>('kk_last_progress');
    lastSegmentCount =
        _lib.lookupFunction<KKLastSegmentCountNative, KKLastSegmentCount>('kk_last_segment_count');
    lastSegmentGet =
        _lib.lookupFunction<KKLastSegmentGetNative, KKLastSegmentGet>('kk_last_segment_get');
    lastSegmentConfidence = _lib.lookupFunction<KKLastSegmentConfidenceNative,
        KKLastSegmentConfidence>('kk_last_segment_confidence');
    lastSegmentSpeaker = _lib.lookupFunction<KKLastSegmentSpeakerNative,
        KKLastSegmentSpeaker>('kk_last_segment_speaker');
    lastWordCount = _lib.lookupFunction<KKLastWordCountNative, KKLastWordCount>(
        'kk_last_word_count');
    lastWordGet = _lib.lookupFunction<KKLastWordGetNative, KKLastWordGet>(
        'kk_last_word_get');
    formatLast = _lib.lookupFunction<KKFormatLastNative, KKFormatLast>('kk_format_last');
    engineFree = _lib.lookupFunction<KKEngineFreeNative, KKEngineFree>('kk_engine_free');
    errorString = _lib.lookupFunction<KKErrorStringNative, KKErrorString>('kk_error_string');
  }

  static KikoeFFI? _instance;

  static KikoeFFI load() {
    return _instance ??= KikoeFFI._(_loadLibrary());
  }

  final DynamicLibrary _lib;
  late final int abiVersion;
  late final String versionString;
  late final int gpuEnabled;
  late final KKEngineCreate engineCreate;
  late final KKTranscribe transcribe;
  late final KKTranscribePcm transcribePcm;
  late final KKCancel cancel;
  late final KKLastProgress lastProgress;
  late final KKLastSegmentCount lastSegmentCount;
  late final KKLastSegmentGet lastSegmentGet;
  late final KKLastSegmentConfidence lastSegmentConfidence;
  late final KKLastSegmentSpeaker lastSegmentSpeaker;
  late final KKLastWordCount lastWordCount;
  late final KKLastWordGet lastWordGet;
  late final KKFormatLast formatLast;
  late final KKEngineFree engineFree;
  late final KKErrorString errorString;

  String describeError(int code) => errorString(code).toDartString();
}
