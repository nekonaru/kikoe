# Third-party notices

Kikoe is distributed under the MIT license (see [LICENSE](LICENSE)). It includes
the following third-party components. Full license texts are in the corresponding
source directories.

## whisper.cpp

- Source: https://github.com/ggml-org/whisper.cpp
- License: MIT
- Copyright: The ggml authors
- Location: `third_party/whisper.cpp` (git submodule, pinned to tag v1.9.5)
- Note: whisper.cpp vendors ggml under the same MIT license.

## OpenAI Whisper model weights

- Source: https://github.com/openai/whisper
- License: MIT
- Note: model files are **not** bundled with Kikoe. They are downloaded on
  explicit user request and cached outside the repository.

## FFmpeg

- Source: https://ffmpeg.org
- License: LGPL or GPL depending on build configuration
- Note: FFmpeg is used as a separate program for media decoding. It is not
  linked into Kikoe and is not distributed by this repository. If you
  redistribute Kikoe with FFmpeg bundled, you must comply with the license of
  the FFmpeg build you ship (prefer an LGPL build and keep it as a separate
  dynamic library or program).

## Flutter and Dart packages

The desktop (Windows) and Android apps use Flutter (BSD-style license) and a
small set of Dart and plugin packages, each under a permissive open source
license (MIT or BSD-3-Clause), with `flutter_lints` as the development-time
analyzer. The apps do not use any proprietary or copyleft Dart packages. The
CLI does not use any Dart code.
