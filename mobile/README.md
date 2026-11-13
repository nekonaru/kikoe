# Kikoe mobile (Android)

Flutter Android app for Kikoe. Audio and video are decoded by the platform
(MediaCodec through a method channel), then transcribed by the same C++ core
as the CLI and desktop app via Dart FFI, inside a background isolate.

## Architecture

- `lib/src/kikoe_ffi.dart`: Dart FFI bindings to `core/include/kikoe.h`
  (`kk_transcribe_pcm` for raw PCM, `kk_format_last` for the output formats).
- `lib/src/transcriber.dart`: worker isolate owning the native engine; the UI
  never calls FFI directly.
- `android/app/src/main/kotlin/io/github/nekonaru/kikoe/MainActivity.kt`:
  decodes any supported media to mono 16 kHz float32 PCM (MediaExtractor +
  MediaCodec), with linear resampling. No ffmpeg, no extra audio libraries.
- `lib/src/model_downloader.dart`: model downloads with resume and SHA-256
  verification (curl is not available on Android; registry and checksums are
  mirrored in `lib/src/model_menu.dart`).
- Default model: `small-q5_1` (quantised, ~190 MB, downloaded on first use).

## Building

The app needs `libkikoe_ffi.so` per ABI in `app/src/main/jniLibs/<abi>/`
(gitignored; built from the repository root):

```sh
cmake -S .. -B ../build-android-arm64 -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 -DANDROID_STL=c++_shared \
  -DKIKOE_BUILD_CLI=OFF -DKIKOE_BUILD_TESTS=OFF \
  -DKIKOE_BUILD_FFI=ON -DCMAKE_BUILD_TYPE=Release
cmake --build ../build-android-arm64 --target kikoe-ffi
mkdir -p android/app/src/main/jniLibs/arm64-v8a
cp ../build-android-arm64/libkikoe_ffi.so android/app/src/main/jniLibs/arm64-v8a/
```

Repeat with `ANDROID_ABI=x86_64` for the emulator. Then:

```sh
flutter run           # debug on a connected device/emulator
flutter build apk --release
```

## Notes

- The APK requests only `INTERNET` (for model downloads) and
  `POST_NOTIFICATIONS` (progress). Transcription itself is offline.
- Media decoding depends on the device's platform codecs; WAV/MP3/M4A/MP4
  work broadly, but an unusual container may fail with a clear error.
- Sharing into the app: send an audio or video file to Kikoe from any app;
  the transcription starts automatically once the model is downloaded.
