<p align="center">
  <img src="assets/brand/kikoe-tile.svg" alt="Kikoe icon" width="128" height="128">
</p>

# Kikoe

**Free, unlimited, offline audio/video transcription. No account, no quota, no cloud.**

Kikoe (聞こえ, from Japanese *kikoeru*, "to be heard") turns audio and video
files into text and subtitles entirely on your device. It is built on
[whisper.cpp](https://github.com/ggml-org/whisper.cpp), wrapped in a small C++
core, with a CLI today and desktop and Android apps planned from the same core.

> Status: early development. The transcription pipeline is being built in
> stages, see the [roadmap](#roadmap). Use at your own risk and expect breaking
> changes until v1.0.

## Why

- **Free forever, no limits.** No minutes quota, no subscription, no API key.
- **Private.** Your audio never leaves your device. No telemetry, ever.
- **Better Indonesian support.** Tuned with Indonesian in mind, plus the other
  languages Whisper supports.
- **Easy to install.** One binary or one installer per platform.

## Platforms

| Platform | Status |
| --- | --- |
| CLI (Windows, macOS, Linux) | In development (Stage 1-3) |
| Desktop (Flutter) | Planned (Stage 5) |
| Android (Flutter + FFI) | Planned (Stage 6) |

## Requirements

- CMake 3.16 or newer
- A C++17 compiler (MSVC, GCC, or Clang)
- git (the build pulls in whisper.cpp as a submodule)
- FFmpeg 6 or newer (only needed to decode non-WAV media)

Whisper model files are **not** bundled. You download the model you want
(see [Model strategy](docs/PRD.md#12-strategi-model)); Internet is used only
for that download.

## Build from source

```sh
git clone --recurse-submodules https://github.com/nekonaru/kikoe.git
cd kikoe
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build --output-on-failure
```

On Windows with Visual Studio, add `-G "Visual Studio 17 2022"` if auto-detection
fails, and pick the configuration with `--config Release`.

## Usage

The CLI is under active development. The target interface is:

```sh
kikoe input.mp4 --lang id --model small --format srt --threads 4 -o hasil.srt
kikoe *.mp3 --format txt,srt --outdir hasil/
kikoe --list-models
kikoe --download-model small
```

Check `kikoe --help` once Stage 2 lands. See the [PRD](docs/PRD.md) for the
full functional spec and C API contract.

## Roadmap

| Stage | Scope | State |
| --- | --- | --- |
| 0 | Foundation: repo, CMake, submodule, CI | Done |
| 1 | Minimal CLI: WAV 16 kHz, print text | Done |
| 2 | Any media: FFmpeg, TXT/SRT/VTT/JSON | Done |
| 3 | Comfort: progress, cancel, batch, model manager | Done |
| 4 | Stable C API with versioned header | Done |
| 5 | Desktop app (Flutter) | Done |
| 6 | Android app (Flutter + FFI) | Done |
| 7 | Release: installers, docs, v1.0 | In progress |

## Privacy

Kikoe makes no network requests except model downloads that you explicitly ask
for. There is no telemetry, no analytics, no crash reporting, no account. See
[SECURITY.md](SECURITY.md) for how to report a vulnerability.

## Third-party components

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT), included as a git
  submodule in `third_party/whisper.cpp`
- [OpenAI Whisper](https://github.com/openai/whisper) model weights (MIT),
  downloaded on demand, never bundled
- FFmpeg (LGPL or GPL depending on build), used as a separate program for media
  decoding, not linked into Kikoe

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the full list and
license texts.

## License

[MIT](LICENSE)

---

Bahasa Indonesia: [README.id.md](README.id.md)
