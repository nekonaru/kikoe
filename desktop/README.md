# Kikoe desktop

Flutter desktop front end for the Kikoe transcription core. It calls the C
API in `kikoe_ffi` (built from the repository root with CMake) through Dart
FFI, inside a background isolate; the UI never touches FFI directly.

## Layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | UI: drop zone, queue, model/language/format controls |
| `lib/src/app_state.dart` | App state and queue processor |
| `lib/src/transcriber.dart` | Background isolate that owns the engine and runs FFI calls |
| `lib/src/kikoe_ffi.dart` | Hand-written FFI bindings to `core/include/kikoe.h` |
| `lib/src/model_menu.dart` | Model registry mirror (keep in sync with `core/src/model/model_registry.cpp`) |
| `assets/icon.png` | App icon (derived from the brand mark) |

## Running

1. Build the FFI library from the repository root:
   `cmake -S .. -B ../build -DCMAKE_BUILD_TYPE=Release && cmake --build ../build --config Release`
2. Copy the library next to the app executable, or set `KIKOE_FFI_PATH` to it
   (`build/Release/kikoe_ffi.dll` on Windows, `libkikoe_ffi.so` on Linux,
   `libkikoe_ffi.dylib` on macOS).
3. `flutter run -d windows` (or `linux`, `macos`).

Runtime dependencies: FFmpeg on PATH for non-WAV media. Whisper model files
are downloaded on first use (Settings shows download progress) or side-loaded
into the cache directory reported by the app.

## Notes

- All transcription happens in a worker isolate; callbacks update the queue UI.
- Windows builds of this project use Flutter plugins, which require Windows
  Developer Mode (Settings > Privacy & security > For developers).
- The app makes no network requests except model downloads that you start.
