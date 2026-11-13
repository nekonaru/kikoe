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
    versionString =
        _lib.lookupFunction<KKVersionStringNative, KKVersionString>('kk_version_string')().toDartString();
    engineCreate = _lib.lookupFunction<KKEngineCreateNative, KKEngineCreate>('kk_engine_create');
    transcribe = _lib.lookupFunction<KKTranscribeNative, KKTranscribe>('kk_transcribe');
    transcribePcm = _lib.lookupFunction<KKTranscribePcmNative, KKTranscribePcm>('kk_transcribe_pcm');
    cancel = _lib.lookupFunction<KKCancelNative, KKCancel>('kk_cancel');
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
  late final KKEngineCreate engineCreate;
  late final KKTranscribe transcribe;
  late final KKTranscribePcm transcribePcm;
  late final KKCancel cancel;
  late final KKFormatLast formatLast;
  late final KKEngineFree engineFree;
  late final KKErrorString errorString;

  String describeError(int code) => errorString(code).toDartString();
}
