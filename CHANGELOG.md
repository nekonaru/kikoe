# Changelog

All notable changes to Kikoe are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

## v3.0.0

The largest Kikoe release so far. Word-level timing, speaker detection, editor operations, saved prompts, and CLI configuration all ship together. No model was removed.

### New features

- **Word-level timestamps.** Both apps and the CLI can collect timing for every word. SRT and VTT exports use word cues when this is enabled. The CLI flag is `--word-timestamps`.
- **Speaker detection.** Tinydiarize labels speaker turns as `SPEAKER_00`, `SPEAKER_01`, and so on. Both apps expose a toggle; CLI uses `--diarize`.
- **Editor operations.** Split a segment at its midpoint, merge with the next segment, delete a segment, and clean repeated words that Whisper sometimes hallucinates. All operations are pure helpers with unit tests.
- **Prompt library.** Save the current custom vocabulary under a name, switch between presets, and remove them. Prompts persist locally.
- **CLI configuration file.** `kikoe.toml` supplies defaults for model, language, quality, VAD, prompt, format and threads. Explicit flags still override it. Use `--config FILE` for another path.
- **CLI prompt file.** `--prompt-file FILE` reads a multi-line initial prompt from disk.
- **C API accessors.** `kk_last_segment_confidence`, `kk_last_segment_speaker`, `kk_last_word_count` and `kk_last_word_get` expose the new data. ABI minor version is 5.

### Improvements

- **Flash attention and carried prompts** from v2.4.0 remain active.
- **Confidence is measured**, not guessed: it is the average token probability from whisper.cpp.
- **Android suite is now 29 tests, desktop 21**, including new coverage for split, merge, cleanup and repeated-word removal.

## v2.5.0

A runtime audit release. Two progress anomalies were fixed and history became searchable.

### New features

- **Search history.** Both apps filter saved transcriptions by file name or transcript text, case-insensitively. An empty query shows everything; a query with no matches shows an explicit empty state.

### Bug fixes

- **Finish estimate no longer counts media decoding.** The clock now starts at the first real transcription percentage. Decoding reports no percentage, so counting it inflated the estimate on long videos.
- **A reused engine can no longer flash a stale 100 percent.** Progress values outside the transcribing stage are ignored in both apps, and the desktop app waits for the first real percentage before starting its clock.

### Improvements

- **`historyMatches` is a pure helper** with unit tests in both apps. Android suite is now 23 tests, desktop 15.

## v2.4.0

A speed and accuracy release. Transcription can now be tuned from the UI, and live progress includes a measured finish estimate.

### New features

- **Speed and quality presets.** Both apps offer Fast, Balanced and Accurate. A preset sets a starting model, VAD and decoding strategy. Every existing model, including `medium-q5_0` and `large-v3-turbo-q5_0`, stays in the picker and can override the preset at any time.
- **Live finish estimate.** The progress bar now shows an estimated finish time beside the percentage. It is derived from observed progress, smoothed so it does not jump, and hidden until enough data exists. The decoding stage stays indeterminate because the decoder reports no percentage.
- **Accurate mode uses beam search.** `kk_options.quality` selects greedy or beam-5 decoding. CLI gains `--quality fast|balanced|accurate`; C ABI minor version is 4.

### Improvements

- **Flash attention is enabled** in the whisper context, lowering peak memory on long audio.
- **Custom vocabulary carries through every decode window** via `carry_initial_prompt`, so names and jargon stay correct deep into a long recording.
- **Benchmark script** (`scripts/benchmark_transcribe.sh`) records wall time for model and quality combinations. Local measurements on the 11 second JFK sample: tiny 0.81s, small-q5_1 6.52s, small-q5_1 with VAD 6.23s, small-q5_1 with VAD and beam-5 6.95s.
- **ETA logic lives in a pure helper** with unit tests in both apps. Android suite is now 18 tests, desktop 11.

## v2.3.1

A stability release from a runtime audit of the released Android build. Two real races could silently corrupt or skip a transcription; both are fixed and covered by tests.

### Bug fixes

- **Share now always auto-starts when the model is cached.** A share that opened the app could be handled before `ensureStarted()` loaded the saved model and created the model directory. `selectedModelCached` was still false, so the file loaded but transcription never started. Share handling now waits for startup and replays the newest pending batch once the engine is ready.
- **Stale job events can no longer pollute a new transcript.** If a new share arrived while a job was running, the old worker's segment, progress and done events were applied to the new job by id-less handling. Worker events are now correlated with an active job id; events from a superseded job are ignored, and changing the input cancels the job still running.

### Improvements

- **`ShareHandler` in the Android app** makes the startup/share ordering explicit and testable.
- **`AppState` accepts an injected `Transcriber`** so worker events can be simulated in unit tests.
- **Seven new tests** cover share replay ordering and stale event filtering; the Android suite now runs 14 tests.

## v2.3.0

A real post-transcription workflow release: fix repeated words and subtitle drift without leaving the editor.

### New features

- **Find & replace across all segments.** The transcript editor now has a find/replace panel with an optional case-sensitive mode. One action updates every matching segment, so a model that consistently mishears a name can be corrected in seconds.
- **Timing shift.** A millisecond offset moves every segment start/end together, clamped at zero, so subtitles that lead or lag the audio can be aligned from the editor. All exports use the edited text and shifted timestamps.

### Improvements

- **Pure logic helpers** (`transcript_editor_logic.dart`) keep find/replace and timing shifts unit tested, independent of Flutter widgets.
- **Fully localized** in English and Indonesian.

## v2.2.0

A big feature release: the apps are no longer limited to the built-in model registry.

### New features

- **Import your own ggml model.** Both desktop and Android can import any `.bin` or `.gguf` model through a file picker. The file is copied into the app's model directory, registered in the picker, verified by file existence, and used directly by the existing FFI `kk_engine_create(model_path)` path. No core change was needed: the CLI already accepted `--model PATH`, now the apps do too.
- **Model management.** Imported models are persisted in SharedPreferences, can be selected or removed from the model section, and show their size in MB. Removing deletes the file and clears the selection safely.

### Notes

- Imported models have no built-in SHA-256 entry; they are used as-is, the same way CLI `--model PATH` works.
- All new labels are localized in both English and Indonesian.

## v2.1.0

Completes the bilingual UI claim of v2.0.0: the FAQ and remaining UI strings are now genuinely localized.

### Improvements

- **All FAQ questions and answers translated.** The 23 FAQ entries in each app now render in Bahasa Indonesia when the locale is Indonesian, through a dedicated `faqId` map. v2.0.0 only translated chrome strings and left the FAQ in English.
- **Privacy and download prompts translated.** Storage-permission dialogs, the "not downloaded yet" hint, the share hint, the status bar and the app tagline now follow the selected locale.
- **Test coverage.** A new `faq_l10n_test.dart` in each app verifies FAQ translation and safe fallback, so a future regression cannot silently reintroduce English-only content.

### Note

v2.0.0 claimed a fully localized UI while the FAQ and several prompts were still English. This release corrects that claim.

## v2.0.0

The first release with a fully localized user interface. English remains the source; Bahasa Indonesia is a real translation, not a stub.

### New features

- **Bilingual UI (English / Bahasa Indonesia).** Both apps translate their visible UI strings through a central `L10n` layer. A Language tile in About switches locale; the choice is persisted and applied across the whole widget tree.
- **Localization tests.** Each app has a test proving English returns source text, Indonesian translates known keys, and unknown strings fall back safely.

### Notes

- English remains the source of every string. Indonesian translations that do not yet exist fall back to English rather than rendering blank.
- This is a major version because the UI language system is new; no existing workflow changed.

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
