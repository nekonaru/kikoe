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

## Scope notes

- Kikoe makes no network requests except model downloads explicitly started by
  the user. Any unexpected network traffic is a security bug.
- Kikoe never collects telemetry. Any data leaving the device without an
  explicit user action is a security bug.
- Media decoders (FFmpeg) are a large attack surface. Keep FFmpeg updated.
