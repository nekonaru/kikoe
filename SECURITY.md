# Security policy

## Supported versions

Kikoe is in early development. Only the latest release is supported.

| Version | Supported |
| --- | --- |
| latest release | yes |
| older releases | no |

## Reporting a vulnerability

Do not open a public issue for a security problem. Report it privately using
GitHub's private vulnerability reporting:

https://github.com/nekonaru/kikoe/security/advisories/new

Please include: what you found, how to reproduce it, and the impact. You will
get an acknowledgement within 7 days. If the report is accepted, a fix and a
security release will follow as soon as practical.

## Verifying downloads

Android APKs published on GitHub Releases are signed with the Kikoe release
key. Verify the certificate SHA-256 fingerprint before installing:

`06:87:03:24:C4:97:56:DE:7D:B3:B0:8D:A4:F2:31:55:44:42:12:6E:41:33:F9:23:56:EC:56:64:D5:CF:4B:9A`

The Windows desktop bundle and the CLI binaries are not code-signed; Windows
SmartScreen will warn on first run. The release zip ships the MIT license and
the README, and every artifact is built by CI from the tagged commit.

## Scope notes

- Kikoe makes no network requests except ones you start yourself: model downloads and the optional update check in About. Any other network traffic is a security bug.
- Kikoe never collects telemetry. Any data leaving the device without an
  explicit user action is a security bug.
- See [PRIVACY.md](PRIVACY.md) for the full privacy policy.
- Media decoders (FFmpeg) are a large attack surface. Keep FFmpeg updated.
