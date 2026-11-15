# Changelog

All notable changes to Kikoe are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Kikoe uses semantic
versioning; until v1.0, the public C API and CLI flags may change between
releases.

## [Unreleased]

## [1.0.1] - 2026-11-15

### Security

- **Android APKs are now signed with the Kikoe release key**, not the debug
  key. CI fails a tagged build when the signing secrets are missing. Verify
  the certificate SHA-256 fingerprint: `06:87:03:24:C4:97:56:DE:7D:B3:B0:8D:A4:F2:31:55:44:42:12:6E:41:33:F9:23:56:EC:56:64:D5:CF:4B:9A`.
  Apps installed from v1.0.0 must be uninstalled before installing v1.0.1,
  because the certificate changed.
- **Model downloads and the ffmpeg invocation no longer pass
  shell-interpretable characters** to the shell; arguments are quoted
  per-platform and anything unexpected fails closed.
- **`android:allowBackup="false"` and `usesCleartextTraffic="false"`** are set
  in the release manifest, so transcripts and models stay out of cloud backups
  and no cleartext traffic is ever attempted.
- **Versions are consistent**: the tag, CLI `--version` output, CMake project
  version and app versions all say 1.0.1 (v1.0.0 shipped binaries reporting 0.1.0).

### Fixed

- Version-string consistency across the C API, CLI, build system and both
  apps (see the last line of Security above).

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

