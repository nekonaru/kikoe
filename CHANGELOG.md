# Changelog

All notable changes to Kikoe are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

## v1.9.0

An audit release: a dead GPU switch is removed from CPU-only builds and progress polling no longer rebuilds the UI on every tick.

### Improvements

- **`kk_gpu_enabled()` added to the C API.** Reports whether the loaded library was built with a GPU backend. The desktop app now hides the "Use GPU" toggle when the official CPU-only build cannot honor it.
- **Progress polling optimized.** The desktop UI only rebuilds when the percentage actually changes, instead of on every 80 ms tick.

## v1.8.0

A format and verification release: two new export formats and CI that finally checks a real transcription.

### New features

- **Markdown export (`md`).** Transcript with timestamps as a readable Markdown document, for notes and publishing.
- **CSV export (`csv`).** `index,start_ms,end_ms,text` with RFC-style quoting, for spreadsheets and subtitle tooling.

### Improvements

- **CI end-to-end transcription.** A new Ubuntu step downloads the tiny-q5_1 model, transcribes the bundled JFK sample and asserts the expected text, so a merge is never green on `--help` alone.
- `--help`/`--version` and both apps' format pickers now list all six output formats.

## v1.7.0

A convenience and desktop-integration release: save finished transcripts without an extra tap, a real CLI --version, and a Linux app-menu launcher.

### New features

- **Save automatically.** Optional, persisted setting. When enabled, a finished transcription is written immediately to the output folder (SRT on mobile, the chosen save format on desktop). Off by default.
- **CLI `--version`.** Prints `kikoe 1.7.0` and exits; no model or media needed.
- **Linux launcher.** The Linux bundle now ships a freedesktop `kikoe.desktop` file and a 512x512 icon, so Kikoe appears in GNOME/KDE application menus after copying two files into the user's local share directory.

### Improvements

- Version string is consistent across CLI --version, --help, C API, CMake and both app manifests.

## v1.6.0

A native-polish release: desktop keyboard shortcuts, audit cleanup and CI verification going forward.

### New features

- **Desktop keyboard shortcuts.** Ctrl/Cmd+O picks files, Ctrl/Cmd+Enter starts the queue, Esc cancels the current transcription. The window always has focus so shortcuts work inside the queue and the control panel alike.
- **In-app About shortcut still opens from the app bar icon; keyboard shortcuts are now documented in the FAQ.**

### Improvements

- **Desktop CMake HOMEPAGE_URL points at the real repository** (`https://github.com/nekonaru/kikoe`).
- **Android build.gradle.kts literal kept** (template TODO removed; application ID already correct for production).

## v1.5.0

A distribution-focused release: Linux and macOS desktop apps join Windows, and the apps release now reaches every major desktop platform from one C++ core.

### New features

- **Linux desktop app.** New `kikoe-linux-x64.tar.gz` bundle with the `kikoe_desktop` GTK binary; Flutter + FFI, same drag & drop queue, same models, same output folder contract.
- **macOS desktop app.** New `kikoe-macos-x64.zip` with the `Kikoe.app` (Swift runner, Flutter + FFI). Reached full parity with the Windows app on the release CI.
- **macOS sandbox entitlements.** Release and debug profiles now grant `network.client`, `files.user-selected.read-write` and `files.downloads.read-write`, so model downloads, input picking and saving work out of the sandbox.

### Improvements

- **Release CI ships Linux and macOS desktop bundles** alongside Windows; release notes and README now cover all four platforms.
- **Docs and FAQ reflect the new platforms.** Install, build, CI table, desktop bundle warning FAQ, project tree and privacy policy are updated and kept EN/ID in sync.

## v1.4.0

A feature release focused on pipeline robustness and polishing the native path.

### New features

- **Live progress during transcription.** Both apps now poll `kk_last_progress()` (a new versioned C API with relaxed atomic reads, safe to call from any isolate) while the worker is blocked inside `whisper_full()`, instead of showing a static bar.
- **Live progress in the Android notification.** The system progress indicator now updates from the same native poll, at parity with the in-app bar.
- **Engine hand-off event.** Workers emit `engineReady` with the native engine pointer so the UI can poll safely without crossing isolate boundaries through raw memory.

### Improvements

- **Version consistency.** Tag, CLI banner, C API version, CMake project and both apps report 1.4.0.

## v1.3.0

New features since v1.2.0: in-app transcript editor, history library, custom vocabulary hint, and a save button that no longer depends on the worker.

### New features

- **Transcript editor.** Fix recognition mistakes per segment before saving. SRT and VTT exports keep exact timestamps; JSON exports escape Unicode correctly.
- **History library.** Tap the history icon to see your last 50 transcriptions with word counts; reopen, copy, re-export or delete any of them.
- **Custom vocabulary.** An optional hint field biases the decoder toward your product names, places and spellings (persisted). On by default for nothing; you opt in per launch.
- **Local format rendering.** Save and share render TXT, SRT, VTT and JSON in Dart, matching the core formatter byte-for-byte; edits are reflected immediately.

### Improvements

- **Tap-to-copy transcript.** Both apps copy the full text in one tap.
- **Per-file state retention on Android.** Queue of picked/shared files now shows progress, stepping through Next; each file's save output is tracked separately.
- **Settings persist across restarts** (model, language, translate, VAD, vocabulary).
- **Save never overwrites.** Existing files get -2, -3 suffixes. Desktop app also gains an Open output folder button.

### Bug fixes

- **CLI VAD path lookup** uses the registry instead of a hard-coded filename.

## v1.2.0

A feature release: silence filtering with Silero VAD in both apps, persistent settings, multi-file share and pick on Android, and a batch of audit fixes.

### New features

- **Silero VAD in both apps.** New Filter silence toggle trims silent regions before transcription. The Silero model (0.9 MB) downloads on first use.
- **Persistent settings.** Your model, language, translate and VAD preferences survive app restarts.
- **Multi-file share and pick on Android.** Sharing or picking several audio or video files queues them all; the app processes them one at a time.
- **Copy transcript button.** One tap copies the full transcript to the clipboard (desktop queue items and the mobile transcript card).
- **Open output folder (desktop).** Jump straight to where the transcript was saved.

### Improvements

- **No silent overwrite.** Saving a transcript never overwrites an existing file; the app appends -2, -3, and so on when the name is taken.
- **Model download errors are visible.** Desktop now shows the error instead of failing silently.
- **Mobile share intent is fully honored.** All shared files reach the queue, not just the first.
- **Larger Android decode pool.** Media decoding runs off the UI thread.

### Bug fixes

- **CLI VAD path.** The Silero model path is resolved from the model registry instead of a hardcoded filename.

## v1.1.0

A feature release: About, sponsor and complete FAQ in-app, a Downloads/kikoe default output folder, and a first-launch storage notice on Android.

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
