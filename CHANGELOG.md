# Changelog

All notable changes to Kikoe are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### New features

- **About screen.** Author identity, GitHub profile link, and a tap-to-check update check against the latest GitHub release.
- **Sponsor screen.** GitHub Sponsors, Saweria, SociaBuzz and BagiBagi, one tap each, opened in the browser.
- **Complete in-app FAQ.** 18 answers covering storage, models, formats, accuracy, permissions, updates, licensing and support.
- **Privacy policy screen and PRIVACY.md.** The policy in-app and in the repository.
- **Open source licenses screen.** MIT texts for Kikoe and whisper.cpp, plus credits for ggml, Flutter, FFmpeg and Whisper model weights.

### Improvements

- **Downloads/kikoe by default.** Transcripts now save into Downloads/kikoe on Android and desktop instead of next to the source file. Desktop keeps a custom folder option; Reset returns to the default.
- **First-launch storage notice on Android.** On Android 9 and below the app asks for the legacy storage permission once; on Android 10+ saving uses MediaStore and no permission is requested.
- **Refined UI and UX.** New app bar with FAQ and About actions, richer pick card, consistent section cards, and an About hub (version, sponsor, privacy, licenses) behind the info icon.
- **Smoother Android decode.** Media decoding runs on a background thread instead of the UI thread, so the app stays responsive on long files.
- **Mobile save action.** Transcripts save straight to Downloads/kikoe; share is available as a secondary action.
- **Quieter release logging.** Debug logging is gated to debug builds.

## v1.0.1

Security release: release-key-signed APKs, a fail-closed download path, a hardened Android manifest, and consistent version strings.

### Improvements

- **Release signing.** Android APKs are now signed with the Kikoe release key instead of the debug key, and tag builds fail when the signing secrets are missing. Verify the certificate fingerprint in SECURITY.md.
- **Fail-closed downloads.** Model downloads and the ffmpeg call no longer pass shell-interpretable characters to the shell; unexpected input aborts instead of running.
- **Hardened manifest.** Backups and cleartext traffic are now explicitly disabled (`allowBackup="false"`, `usesCleartextTraffic="false"`).
- **Download verification.** CI verifies the signature of every APK with `apksigner` before publishing.
- **Dependency updates.** Dependabot now proposes weekly updates for GitHub Actions, Dart and Gradle dependencies.

### Bug fixes

- **Version drift.** The tag, C API version, CLI `--help` banner, CMake project version and both apps all report 1.0.1. The v1.0.0 binaries reported 0.1.0.

## v1.0.0

First public release: offline audio and video transcription to text and subtitles on Android, Windows desktop and the command line.

### New features

- **Transcription engine.** whisper.cpp v1.9.5 exposed through a stable, versioned C API, used by every surface.
- **CLI.** Transcribe any audio or video file to TXT, SRT, VTT or JSON. Batch mode, per-file outputs, silence filtering with Silero VAD, and a verified, resumable model downloader (`kikoe --download-model`).
- **Windows desktop app.** Drag and drop queue, per-file TXT/SRT/VTT/JSON export, custom output folder, model management with checksum verification.
- **Android app.** Same core over Dart FFI; on-device transcription with MediaCodec-based decoding (no FFmpeg needed), share-to-Kikoe, ongoing notification with progress.
- **Windows desktop bundle.** `kikoe-windows-x64.zip`: `Kikoe.exe` plus `kikoe_ffi.dll`.
- **Android APKs.** Split per ABI; CLI zips for Windows, macOS and Linux.
- **CI-built releases.** Every artifact is built by CI from the tagged commit; the repo is scanned for secrets before every push.
- **Security policy and notices.** SECURITY.md, third-party notices, bilingual README and changelog.
