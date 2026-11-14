# Changelog

All notable changes to Kikoe are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Kikoe uses semantic
versioning; until v1.0, the public C API and CLI flags may change between
releases.

## [Unreleased]

## [1.0.0] - 2026-11-14

### Added

- Transcription engine built on whisper.cpp v1.9.5, exposed through a stable
  versioned C API, used by every product surface below.
- **CLI**: transcribe any audio or video file to TXT, SRT, VTT or JSON.
  Batch mode, per-file outputs, silence filtering with Silero VAD, and an
  automatically verified and resumable model downloader (`kikoe --download-model`).
- **Desktop app** (Windows, macOS, Linux): drag & drop queue, live preview,
  per-file TXT/SRT/VTT/JSON export, model management with checksum verification.
- **Android app**: same core over Dart FFI; on-device transcription with
  MediaCodec-based decoding (no FFmpeg needed), share-to-Kikoe, ongoing
  notification with progress.
- **Desktop bundle** (`kikoe-windows-x64`): `Kikoe.exe` plus `kikoe_ffi.dll`.
- **Android APK** (`kikoe-android-apks`), split per ABI.
- CI builds all artifacts on Windows, macOS and Linux.
- Security policy, third-party notices, bilingual README and changelog.

### Security

- All published builds keep the audio on-device. The only network calls are
  explicit model downloads, verified by SHA-256.

