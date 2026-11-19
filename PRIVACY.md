# Privacy policy

Effective: v1.6.0 · applies to Kikoe (CLI, desktop and Android apps)

The short version: Kikoe makes no network requests except the ones you start
yourself (model downloads and the update check). Your audio, video,
transcripts and media files never leave your device. There is no account, no
telemetry, no analytics and no crash reporting.

## What Kikoe collects

Nothing. Kikoe has no servers, no accounts, no analytics SDK, no ads and no
tracking. The app does not read your contacts, location, camera, microphone
(transcription works on files, not live audio) or clipboard.

## Network requests

Exactly two kinds, both user-initiated:

1. Model downloads from the public whisper.cpp model hub on Hugging Face,
   which you start yourself (CLI or the in-app button).
2. The update check in About, which you start by tapping Version.

Both transfer no personal data. If you open a link (GitHub, sponsors, a
release), your browser talks to that site under its own privacy policy.

## Where your files live

Transcripts you save are written to the Downloads/kikoe folder on your device
by default. The desktop app can write to any folder you pick; Reset takes you
back to the default. Kikoe does not upload transcripts.

## Model files

Whisper model files are downloaded once into the app's private storage (or the
CLI cache directory: %LOCALAPPDATA%\kikoe\models, ~/.cache/kikoe/models on
Linux, ~/Library/Caches/kikoe/models on macOS). They are never sent anywhere.
Downloads are verified by SHA-256 before use.

## Permissions

Android requests: INTERNET (model download and update check),
POST_NOTIFICATIONS (transcription progress), and WRITE_EXTERNAL_STORAGE on
Android 9 and below (saving to Downloads/kikoe). On Android 10+ saving uses
the MediaStore API and this permission is not requested.

## Third parties

- github.com (source, releases, update check)
- huggingface.co (model files)
- sponsor links, optional and opened only on your tap: GitHub Sponsors,
  Saweria, SociaBuzz, BagiBagi

Kikoe receives no data and no payment information from those sites.

## Data deletion

Uninstalling the app removes its private data. Transcripts in Downloads/kikoe
are ordinary files you keep; delete them with your file manager.

## Children

Kikoe collects no data from anyone, including children. It is a
general-purpose utility.

## Changes and contact

This policy may change with new releases; the current version is always
in-app and in this file. Questions: open a GitHub issue, or report security
problems privately via the repository's security advisories.
