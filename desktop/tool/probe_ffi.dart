// Smoke probe for the Kikoe C API through Dart FFI.
// Replicates exactly the calls the app workers make, so the FFI contract
// (struct layouts, symbol exports, memory ownership) is verified end to end.
//
// Printing to stdout is the point of this tool; logging would add nothing.
// ignore_for_file: avoid_print
//
// Usage:
//   KIKOE_FFI_DLL=path/to/kikoe_ffi.dll KIKOE_MODEL=path/to/model.bin KIKOE_MEDIA=jfk.wav dart run tool/probe_ffi.dart
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

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

final class KkOptions extends Struct {
  external Pointer<Utf8> language;
  @Int32()
  external int translate;
  external Pointer<Utf8> initialPrompt;
}

final class KkSegment extends Struct {
  @Int64()
  external int startMs;
  @Int64()
  external int endMs;
  external Pointer<Utf8> text;
}

void main() {
  final dllPath = Platform.environment['KIKOE_FFI_DLL'];
  final modelPath = Platform.environment['KIKOE_MODEL'];
  final mediaPath = Platform.environment['KIKOE_MEDIA'];
  if (dllPath == null || modelPath == null || mediaPath == null) {
    stderr.writeln('Set KIKOE_FFI_DLL, KIKOE_MODEL and KIKOE_MEDIA');
    exitCode = 2;
    return;
  }

  final lib = DynamicLibrary.open(dllPath);

  // kk_abi_version
  final abi = lib.lookupFunction<Int32 Function(), int Function()>('kk_abi_version')();
  print('abi version: $abi');

  // kk_engine_create
  final create = lib.lookupFunction<
      Pointer<Void> Function(Pointer<KkEngineParams>, Pointer<Int32>),
      Pointer<Void> Function(Pointer<KkEngineParams>, Pointer<Int32>)>('kk_engine_create');
  final params = calloc<KkEngineParams>();
  params.ref.modelPath = modelPath.toNativeUtf8();
  params.ref.nThreads = 0;
  params.ref.useGpu = 0;
  params.ref.vad = 0;
  params.ref.vadModelPath = nullptr;
  final err = calloc<Int32>();
  final engine = create(params, err);
  final createErr = err.value;
  calloc.free(err);
  calloc.free(params.ref.modelPath);
  calloc.free(params);
  print('engine create err: $createErr');
  if (engine == nullptr || createErr != 0) {
    stderr.writeln('engine create failed');
    exitCode = 1;
    return;
  }

  // kk_transcribe (no callbacks; segments harvested after the call)
  final transcribe = lib.lookupFunction<
      Int32 Function(
          Pointer<Void>,
          Pointer<Utf8>,
          Pointer<KkOptions>,
          Pointer<NativeFunction<Void Function(Int32, Pointer<Void>)>>,
          Pointer<NativeFunction<Void Function(Pointer<KkSegment>, Pointer<Void>)>>,
          Pointer<Void>),
      int Function(
          Pointer<Void>,
          Pointer<Utf8>,
          Pointer<KkOptions>,
          Pointer<NativeFunction<Void Function(Int32, Pointer<Void>)>>,
          Pointer<NativeFunction<Void Function(Pointer<KkSegment>, Pointer<Void>)>>,
          Pointer<Void>)>('kk_transcribe');

  final mediaPtr = mediaPath.toNativeUtf8();
  final languagePtr = 'en'.toNativeUtf8();
  final options = calloc<KkOptions>();
  options.ref.language = languagePtr;
  options.ref.translate = 0;
  options.ref.initialPrompt = nullptr;

  final rc = transcribe(engine, mediaPtr, options, nullptr, nullptr, nullptr);
  print('transcribe rc: $rc');
  calloc.free(options);
  calloc.free(mediaPtr);
  calloc.free(languagePtr);
  if (rc != 0) {
    stderr.writeln('transcribe failed');
    exitCode = 1;
    return;
  }

  // kk_last_segment_count / kk_last_segment_get
  final lastSegmentCount =
      lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>(
          'kk_last_segment_count');
  final lastSegmentGet = lib.lookupFunction<
      Int32 Function(Pointer<Void>, Int32, Pointer<KkSegment>),
      int Function(Pointer<Void>, int, Pointer<KkSegment>)>('kk_last_segment_get');

  final count = lastSegmentCount(engine);
  print('segments: $count');
  if (count < 1) {
    stderr.writeln('no segments harvested');
    exitCode = 1;
    return;
  }
  for (var i = 0; i < count; i++) {
    final seg = calloc<KkSegment>();
    lastSegmentGet(engine, i, seg);
    print('segment $i [${seg.ref.startMs}-${seg.ref.endMs}]: ${seg.ref.text.toDartString()}');
    calloc.free(seg);
  }

  // kk_format_last: query then render as SRT
  final formatLast = lib.lookupFunction<
      Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Uint64, Pointer<Uint64>),
      int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Uint64>)>(
      'kk_format_last');
  final formatPtr = 'srt'.toNativeUtf8();
  final written = calloc<Uint64>();
  formatLast(engine, formatPtr, nullptr, 0, written);
  final needed = written.value;
  final buf = calloc<Uint8>(needed).cast<Utf8>();
  formatLast(engine, formatPtr, buf, needed, written);
  final srt = buf.toDartString();
  print('--- SRT ---');
  stdout.write(srt);
  calloc.free(buf.cast<Uint8>());
  calloc.free(formatPtr);
  calloc.free(written);

  // kk_engine_free
  final engineFree = lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
      'kk_engine_free');
  engineFree(engine);
  print('probe ok');
}
