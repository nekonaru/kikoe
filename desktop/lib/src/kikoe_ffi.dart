/// FFI bindings to the Kikoe C API (core/include/kikoe.h).
///
/// The shared library is kikoe_ffi.dll (Windows), libkikoe_ffi.so (Linux),
/// libkikoe_ffi.dylib (macOS). Resolution order:
/// 1. $KIKOE_FFI_PATH, which must point at the library file
/// 2. A library placed next to the executable (this is how the installer ships it)
/// 3. The platform default search path
///
/// Everything in this file may be called from any isolate; the engine itself
/// is created and owned inside the worker isolate (see transcriber.dart).
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

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

typedef KKCancelNative = Void Function(Pointer<Void> engine);
typedef KKCancel = void Function(Pointer<Void> engine);

typedef KKLastSegmentCountNative = Int32 Function(Pointer<Void> engine);
typedef KKLastSegmentCount = int Function(Pointer<Void> engine);

typedef KKLastSegmentGetNative = Int32 Function(
    Pointer<Void> engine, Int32 index, Pointer<KkSegment> outSegment);
typedef KKLastSegmentGet = int Function(
    Pointer<Void> engine, int index, Pointer<KkSegment> outSegment);

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

typedef KKModelCacheDirNative = Pointer<Utf8> Function();
typedef KKModelCacheDir = Pointer<Utf8> Function();

typedef KKDownloadModelNative = Int32 Function(
    Pointer<Utf8> name,
    Pointer<NativeFunction<KkProgressCb>> onProgress,
    Pointer<Void> user);
typedef KKDownloadModel = int Function(
    Pointer<Utf8> name,
    Pointer<NativeFunction<KkProgressCb>> onProgress,
    Pointer<Void> user);

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

const _defaultNames = {
  'windows': 'kikoe_ffi.dll',
  'linux': 'libkikoe_ffi.so',
  'macos': 'libkikoe_ffi.dylib',
};

DynamicLibrary _loadLibrary() {
  final envPath = Platform.environment['KIKOE_FFI_PATH'];
  if (envPath != null && envPath.isNotEmpty && File(envPath).existsSync()) {
    return DynamicLibrary.open(envPath);
  }
  final os = Platform.operatingSystem;
  final name = _defaultNames[os];
  if (name == null) {
    throw UnsupportedError('Kikoe FFI is not packaged for $os');
  }
  final besideExe = File(p.join(p.dirname(Platform.resolvedExecutable), name));
  if (besideExe.existsSync()) {
    return DynamicLibrary.open(besideExe.path);
  }
  return DynamicLibrary.open(name);
}

class KikoeFFI {
  KikoeFFI._(this._lib) {
    abiVersion = _lib.lookupFunction<KKAbiVersionNative, KKAbiVersion>('kk_abi_version')();
    versionString = _lib
        .lookupFunction<KKVersionStringNative, KKVersionString>('kk_version_string')()
        .toDartString();
    engineCreate = _lib.lookupFunction<KKEngineCreateNative, KKEngineCreate>('kk_engine_create');
    transcribe = _lib.lookupFunction<KKTranscribeNative, KKTranscribe>('kk_transcribe');
    cancel = _lib.lookupFunction<KKCancelNative, KKCancel>('kk_cancel');
    lastSegmentCount = _lib.lookupFunction<KKLastSegmentCountNative, KKLastSegmentCount>('kk_last_segment_count');
    lastSegmentGet = _lib.lookupFunction<KKLastSegmentGetNative, KKLastSegmentGet>('kk_last_segment_get');
    formatLast = _lib.lookupFunction<KKFormatLastNative, KKFormatLast>('kk_format_last');
    engineFree = _lib.lookupFunction<KKEngineFreeNative, KKEngineFree>('kk_engine_free');
    errorString = _lib.lookupFunction<KKErrorStringNative, KKErrorString>('kk_error_string');
    modelCacheDir = _lib.lookupFunction<KKModelCacheDirNative, KKModelCacheDir>('kk_model_cache_dir');
    downloadModel = _lib.lookupFunction<KKDownloadModelNative, KKDownloadModel>('kk_download_model');
  }

  static KikoeFFI? _instance;

  /// Load (once) and return the bindings. Throws [UnsupportedError] when the
  /// library cannot be found, with a message suitable for showing in the UI.
  static KikoeFFI load() {
    return _instance ??= KikoeFFI._(_loadLibrary());
  }

  final DynamicLibrary _lib;
  late final int abiVersion;
  late final String versionString;
  late final KKEngineCreate engineCreate;
  late final KKTranscribe transcribe;
  late final KKCancel cancel;
  late final KKLastSegmentCount lastSegmentCount;
  late final KKLastSegmentGet lastSegmentGet;
  late final KKFormatLast formatLast;
  late final KKEngineFree engineFree;
  late final KKErrorString errorString;
  late final KKModelCacheDir modelCacheDir;
  late final KKDownloadModel downloadModel;

  String describeError(int code) {
    final ptr = errorString(code);
    return ptr.toDartString();
  }
}
