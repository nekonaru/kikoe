<div align="center">
  <img src="assets/brand/kikoe-tile.svg" alt="Kikoe logo" width="120" />
  <h1>Kikoe: Offline Audio/Video Transcription</h1>
  <p><b>Transcribe audio and video into text and subtitles entirely on your device,<br/>
  with a CLI, desktop apps for Windows, Linux and macOS, and an Android app.</b></p>

  <a href="https://github.com/nekonaru/kikoe/releases"><img src="https://img.shields.io/github/v/release/nekonaru/kikoe?style=flat-square&color=blue" alt="Release" /></a>
  <a href="https://github.com/nekonaru/kikoe/actions/workflows/ci.yml"><img src="https://github.com/nekonaru/kikoe/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.47.0-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter 3.47.0" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Desktop%20%7C%20CLI-3DDC84?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License: MIT" />
  <img src="https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square" alt="Status: Active" />
</div>

<br />

**English** | [Bahasa Indonesia](README.id.md)

> [!NOTE]
> Kikoe never sends your audio anywhere. Internet is used only when you start a model download yourself.

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Development](#development)
- [Testing](#testing)
- [Security](#security)
- [Continuous Integration](#continuous-integration)
- [FAQ](#faq)
- [Author](#author)
- [License](#license)

---

## About

**Kikoe** (聞こえ, from Japanese *kikoeru*, "to be heard") turns audio and video
files into text and subtitles entirely on your device. It is built on
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) behind a small C++ core
with a versioned C API, shared by the CLI, the desktop app and the Android
app. No account, no quota, no cloud. See [docs/PRD.md](docs/PRD.md) for the
full product spec.

> _"Free, unlimited, offline transcription for everyone."_

---

## Features

### Android app

| Feature | Description |
|---------|-------------|
| **On-device transcription** | The same C++ core over Dart FFI, decoding with MediaCodec, no FFmpeg needed |
| **Silence filtering (VAD)** | Optional Silero VAD trims silent regions before transcription |
| **Transcript editor** | Fix any mistake before saving; SRT/VTT timestamps stay valid |
| **Live progress** | Native progress polled from kk_last_progress(), updates the bar and the notification |
| **History** | Your last 50 transcriptions, on-device, reopen/share anytime |
| **Custom vocabulary** | Bias names and product terms the model keeps mishearing |
| **Share to Kikoe** | Share any audio or video from another app straight into Kikoe |
| **Progress notification** | Ongoing notification with progress while a job runs |
| **Model management** | Download and remove models in-app; checksum verified after every download |

### Desktop app

| Feature | Description |
|---------|-------------|
| **Drag & drop queue** | Queue many files at once, each with its own output |
| **Per-file export** | TXT, SRT, VTT or JSON export per file |
| **Downloads/kikoe default** | Transcripts are saved into Downloads/kikoe out of the box; pick any folder, Reset returns to the default |
| **Model management** | Download and verify models in-app |
| **Transcript editor** | Per-segment editor before saving; SRT/VTT stays valid |
| **Live progress** | Native progress polled from kk_last_progress(), shown per queue item |
| **History** | Your last 50 transcriptions, export from there |
| **Custom vocabulary** | Help the model learn your product and place names |

### CLI

| Feature | Description |
|---------|-------------|
| **Any media** | WAV natively; MP4, MKV, MP3, M4A, FLAC and more through FFmpeg |
| **Output formats** | TXT, SRT, VTT, JSON |
| **Batch mode** | Multiple files with per-file outputs (`--outdir`) |
| **VAD silence filtering** | Optional Silero VAD (`--vad`) |
| **Verified model downloads** | SHA-256 checked after every download, resumable (`kikoe --download-model`) |
| **Whisper language set** | Every language Whisper supports, `--lang <code>` or `auto`, plus translate mode to English |
| **Cancellation** | Ctrl+C cancels cleanly |

### Everywhere

| Feature | Description |
|---------|-------------|
| **Free forever, no limits** | No minutes quota, no subscription, no API key |
| **Private** | Audio never leaves your device, no telemetry ever |
| **Indonesian first** | Tuned with Indonesian in mind, plus every language Whisper supports |
| **One engine** | A single C++ core behind a versioned C API for every surface |

---

## Requirements

| Dependency | Minimum Version | Notes |
|------------|-----------------|-------|
| **CMake** | 3.16 | Builds the core and the CLI |
| **C++17 compiler** | MSVC 2019+, GCC, or Clang | Core and CLI |
| **Git** | any recent | whisper.cpp is a submodule |
| **FFmpeg** | 6 | CLI only; needed to decode non-WAV media |
| **Flutter** | 3.47.0 | Desktop and Android apps; not needed for the CLI |
| **JDK** | 17 | Android build only |
| **Android SDK** | API 37 (compile), API 24+ at runtime | Android build only |
| **Android NDK** | 28.2.13676358 | Android build only |

> [!TIP]
> If you only want to use Kikoe, you do not need Flutter, the JDK, or the Android SDK. Download a release from the [Releases](https://github.com/nekonaru/kikoe/releases) page instead.

### Never used a terminal? Start here

<details>
<summary><b>How to open a terminal on Windows</b></summary>

1. Press the **Windows** key, type `PowerShell`, then press **Enter**
2. A window opens. That is where you type commands
3. Every `cmake`, `git`, `flutter` or `kikoe` command in this guide is typed there, followed by **Enter**

</details>

---

## Installation

### Option A: Download a release (easiest)

1. Open the [Releases](https://github.com/nekonaru/kikoe/releases) page
2. Download the file for your platform:
   - `app-arm64-v8a-release.apk` for most Android phones
   - `app-armeabi-v7a-release.apk` for older 32-bit Android devices
   - `app-x86_64-release.apk` for x86_64 emulators
   - `kikoe-windows-x64.zip` for the Windows desktop app
   - `kikoe-linux-x64.tar.gz` for the Linux desktop app (extract and run the `kikoe_desktop` executable)
   - `kikoe-macos-x64.zip` for the macOS desktop app (unzip, drag Kikoe to Applications; macOS will ask you to confirm the first launch)
   - `kikoe-cli-windows-latest.zip` (Windows), `kikoe-cli-macos-latest.zip` (macOS) or `kikoe-cli-ubuntu-latest.zip` (Linux) for the CLI
3. Android: open the APK on your phone, allow installs from unknown sources if asked. Verify the certificate fingerprint in [SECURITY.md](SECURITY.md) before installing
4. Windows desktop app: extract the zip and run `Kikoe.exe`; Linux desktop: extract the tarball and run `./kikoe_desktop`; macOS desktop: unzip, run Kikoe and confirm at the Gatekeeper prompt
5. CLI: put the binary on your PATH and run `kikoe --help`

> [!IMPORTANT]
> Android needs the "Install unknown apps" permission for the app you install with (browser or file manager), and the notification permission so the progress notification can appear. Nothing else is requested. The desktop apps are not code-signed; Windows SmartScreen and macOS Gatekeeper will warn on first run; see the FAQ for why.

### Option B: Build from source (for development)

#### 1. Get the code

<details>
<summary><b>I have Git installed</b></summary>

```bash
git clone --recurse-submodules https://github.com/nekonaru/kikoe.git
cd kikoe
```

</details>

<details>
<summary><b>I don't have Git</b></summary>

1. Open the repository page on GitHub
2. Click the green **`Code`** button, choose **`Download ZIP`**
3. Extract the ZIP to a folder of your choice, then in the terminal:

```bash
cd kikoe-main
```

Note that the ZIP does not include the whisper.cpp submodule. Building the
CLI from the ZIP requires also fetching `third_party/whisper.cpp` at the
pinned tag; using Git with `--recurse-submodules` is the simple route.

</details>

#### 2. Build and test the CLI

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
```

> [!IMPORTANT]
> `ctest` must report **100% tests passed**.

#### 3. Build the apps

```bash
# Windows desktop app
cd desktop
flutter pub get
flutter build windows --release

# Linux desktop app (Ubuntu 24.04 / APT required)
sudo apt-get install -y ninja-build clang cmake pkg-config libgtk-3-dev libglib2.0-dev libblkid-dev liblzma-dev
cd desktop
flutter build linux --release

# macOS desktop app
cd desktop
flutter build macos --release

# Android app (needs JDK 17, Android SDK 37, NDK 28.2.13676358)
cd mobile
flutter pub get
flutter build apk --release --split-per-abi
```

---

## Usage

### First launch

1. Download a model (only needed once, only when you are online):

   ```bash
   kikoe --download-model tiny
   ```

2. Transcribe something:

   ```bash
   kikoe input.mp4 --lang id --format srt -o hasil.srt
   ```

3. In the apps, tap **Pick an audio or video file** (or drop it on the desktop window) and wait for the transcript to appear

> [!NOTE]
> Whisper models are large files downloaded once and kept in the local cache. `kikoe --list-models` shows what is available and what is already downloaded.

### Everyday use

- `kikoe --format txt,srt,vtt,json input.mp4` for several formats at once
- `kikoe *.mp3 --outdir transcripts/` for a batch
- `kikoe --vad input.mp4` to skip silence
- `kikoe --lang auto input.mp4` to auto-detect the language
- Desktop: save TXT/SRT/VTT/JSON per file; transcripts land in Downloads/kikoe by default (change in the sidebar)
- Android: files save into Downloads/kikoe; share a video from your gallery app into Kikoe

---

## Project Structure

```
kikoe/
├── assets/brand/            # logo and icon assets
├── cli/                     # kikoe command line tool
├── core/                    # C++17 transcription core
│   ├── include/kikoe.h      # versioned C API
│   └── src/                 # engine, decoder, model manager, formatters
├── desktop/                 # Desktop apps for Windows, Linux and macOS (Flutter)
├── mobile/                  # Android app (Flutter + Dart FFI, Kotlin MediaCodec)
├── scripts/                 # release notes builder
├── tests/                   # ctest suite (formatter, C API contract)
├── third_party/whisper.cpp  # git submodule (v1.9.5)
├── .github/workflows/ci.yml # build, test, package, release, secret scan
├── CMakeLists.txt           # core and CLI build
├── LICENSE                  # MIT
├── README.md                # documentation (English)
└── README.id.md             # documentation (Bahasa Indonesia)
```

---

## Development

### Changing the core or CLI

1. Edit the code under `core/` or `cli/`
2. Rebuild: `cmake --build build --config Release`
3. Run the tests: `ctest --test-dir build -C Release --output-on-failure`

### Changing the desktop or Android app

1. Edit the code under `desktop/` or `mobile/`
2. `flutter pub get && flutter analyze && flutter test` in that folder
3. If you changed the C API, bump `kk_abi_version()` in `core/include/kikoe.h`
   and check the FFI probe:

```bat
cd desktop
set KIKOE_FFI_DLL=..\..\build\Release\kikoe_ffi.dll
set KIKOE_MODEL=%LOCALAPPDATA%\kikoe\models\ggml-tiny.bin
set KIKOE_MEDIA=..\third_party\whisper.cpp\samples\jfk.wav
dart run tool\probe_ffi.dart
```

### Adding a model to the registry

1. Add the entry (name, filename, URL, size, SHA-256) to `core/src/model/model_registry.cpp`
2. Add the same entry to `mobile/lib/src/model_menu.dart`
3. Recompute the size and SHA-256 from the published file; never guess them

---

## Testing

Verification before every push, all of these must be clean:

```bash
ctest --test-dir build -C Release --output-on-failure
cd desktop && flutter analyze && flutter test
cd mobile && flutter analyze && flutter test
```

| Check | Requirement |
|-------|-------------|
| `ctest --test-dir build -C Release` | Must report 100% tests passed |
| `flutter analyze` (both apps) | Must report No issues found |
| `flutter test` (both apps) | Must pass the full suite |

Lints are enforced through `analysis_options.yaml` in each app (flutter_lints).
CI runs the same checks on Windows, macOS and Linux on every push and pull request.

---

## Security

Kikoe is a fully offline app with no backend, no accounts and no purchases.
The only network requests are the ones you start yourself: model downloads
from the public whisper.cpp model hub (verified by SHA-256 after every
download) and the update check in About. Release APKs are signed with the
Kikoe release key and the certificate fingerprint is published in
[SECURITY.md](SECURITY.md). Releases are built from tagged commits and the
repository is scanned for secrets before every push. The Android release
manifest disables backups and cleartext traffic.

> [!NOTE]
> See [SECURITY.md](SECURITY.md) for the full security policy and the private reporting route for vulnerabilities, and [PRIVACY.md](PRIVACY.md) for the privacy policy.

---

## Continuous Integration

| Workflow | Purpose |
|----------|---------|
| `ci.yml` (Build and test) | Core build and ctest on Windows, macOS, Linux; CLI zip per OS |
| `ci.yml` (Build desktop) | Desktop bundles for Windows, Linux and macOS |
| `ci.yml` (Build Android APK) | Release APKs, signed, split per ABI |
| `ci.yml` (Release artifacts) | On `v*` tags, creates the GitHub Release with all artifacts |
| `ci.yml` (Secret scan) | gitleaks on every push and pull request |

Dependencies are updated weekly by Dependabot. The install paths in the release notes always match Option A above.

---

## FAQ

<details>
<summary><b>Does Kikoe need the internet?</b></summary>

Only to download whisper models, and only when you ask it to. Transcription itself never uses the network.

</details>

<details>
<summary><b>Which APK should I install?</b></summary>

`app-arm64-v8a-release.apk` on practically all phones made in the last decade. Use `app-armeabi-v7a-release.apk` only on very old 32-bit devices, and `app-x86_64-release.apk` on x86_64 emulators.

</details>

<details>
<summary><b>Android says the installed app conflicts when I install v1.0.1?</b></summary>

The signing certificate changed in v1.0.1. Uninstall the app installed from v1.0.0, then install v1.0.1. Your models and transcripts live in your own storage or inside the app's private folder; the models are re-downloadable.

</details>

<details>
<summary><b>Why do the desktop apps warn on first run?</b></summary>

The desktop bundles are not code-signed (needs an Authenticode certificate for Windows and a Developer ID certificate for macOS, both of which cost money), so SmartScreen and Gatekeeper warn on first launch. You can install them without issue by clicking Run anyway / Open. The artifacts are built by CI from public tagged commits; verify the downloads in [SECURITY.md](SECURITY.md).

</details>

<details>
<summary><b>My video file does not decode?</b></summary>

Install FFmpeg 6 or newer and make sure `ffmpeg` is on your PATH for the CLI. The Android app decodes with MediaCodec and does not need FFmpeg; unmount any DRM-protected content first.

</details>

<details>
<summary><b>Where are models stored and how big are they?</b></summary>

In the local cache (`%LOCALAPPDATA%\kikoe\models` on Windows, `~/.cache/kikoe/models` on Linux, `~/Library/Caches/kikoe/models` on macOS). Roughly 75 MB for `tiny` and up to about 3.1 GB for `large-v3`. Nothing is bundled with the app.

</details>

<details>
<summary><b>Where are my transcripts saved?</b></summary>

Into the Downloads/kikoe folder on your device, by default. The desktop app can write anywhere you pick (Choose… in the sidebar); press Reset to go back to the default. Kikoe never uploads transcripts.

</details>

<details>
<summary><b>How do I support Kikoe?</b></summary>

Star it on GitHub, or sponsor via GitHub Sponsors, Saweria, SociaBuzz or BagiBagi. Links live in About (the info icon) in both apps: About > Sponsor Kikoe.

</details>

---

<details>
<summary><b>Can I edit a transcript after it is done?</b></summary>

Yes. Tap the pencil icon on the transcript header. Each segment becomes a text field; saving replaces the text while keeping SRT/VTT timestamps intact.

</details>

<details>
<summary><b>Where are my past transcriptions?</b></summary>

The history icon (clock) in the app bar lists your last 50. Tap any to view, copy or export it; tap the X to delete it.

</details>

## Author

<div align="center">

| [![Nicolas Dwi Dharma](https://github.com/nekonaru.png?size=100)](https://github.com/nekonaru) |
|:---:|
| **Nicolas Dwi Dharma** |
| [github.com/nekonaru](https://github.com/nekonaru) |

</div>

---

## License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.
