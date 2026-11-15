#!/usr/bin/env python3
"""Build a bilingual GitHub release body from CHANGELOG.md and CHANGELOG.id.md.

Usage: build_release_notes.py <tag> [output]

The changelogs carry the shared content: a one-sentence summary, then
sections (New features / Improvements / Bug fixes in English, Fitur baru /
Peningkatan / Perbaikan bug in Bahasa Indonesia). This script wraps them in
the release body shape, then appends the Install / Update section in both
languages, kept in sync with "Option A" in README.md / README.id.md.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

INSTALL_EN = """## Install / Update

Download the file for your platform from Assets below:

- **Android:** `app-arm64-v8a-release.apk` on most modern phones; `app-armeabi-v7a-release.apk` for older 32-bit devices; `app-x86_64-release.apk` for x86_64 emulators
- **Windows:** `kikoe-windows-x64.zip` (desktop app) or `kikoe-cli-windows-latest.zip` (CLI)
- **macOS:** `kikoe-cli-macos-latest.zip`
- **Linux:** `kikoe-cli-ubuntu-latest.zip`

Requires Android 7.0 (API 24) or newer on Android. Verify the APK certificate fingerprint in SECURITY.md. Windows SmartScreen warns on first run because the desktop bundle is not code-signed."""

INSTALL_ID = """## Instalasi / Update

Unduh file untuk platformmu dari Assets di bawah:

- **Android:** `app-arm64-v8a-release.apk` untuk kebanyakan ponsel modern; `app-armeabi-v7a-release.apk` untuk perangkat 32-bit lawas; `app-x86_64-release.apk` untuk emulator x86_64
- **Windows:** `kikoe-windows-x64.zip` (aplikasi desktop) atau `kikoe-cli-windows-latest.zip` (CLI)
- **macOS:** `kikoe-cli-macos-latest.zip`
- **Linux:** `kikoe-cli-ubuntu-latest.zip`

Membutuhkan Android 7.0 (API 24) atau lebih baru di Android. Verifikasi sidik jari sertifikat APK di SECURITY.md. Windows SmartScreen memperingatkan pada jalan pertama karena bundle desktop belum ditandatangani."""


def extract(path: Path, version: str):
    """Return (summary, sections_block) for '## v<version>' in the changelog."""
    text = path.read_text(encoding="utf-8")
    match = re.search(rf"^## v{re.escape(version)}\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    if not match:
        sys.exit(f"No section '## v{version}' found in {path}")
    body = match.group(1).strip()
    first_section = re.search(r"^### ", body, re.M)
    if not first_section:
        return body.strip(), ""
    summary = body[:first_section.start()].strip()
    sections = body[first_section.start():].strip()
    # Changelogs nest sections under '## vX.Y.Z' as h3; the release body wants h2.
    sections = re.sub(r"^### ", "## ", sections, flags=re.M)
    return summary, sections


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("usage: build_release_notes.py <tag> [output]")
    tag = sys.argv[1]
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("RELEASE_NOTES.md")
    version = tag.lstrip("vV")

    en_summary, en_sections = extract(ROOT / "CHANGELOG.md", version)
    id_summary, id_sections = extract(ROOT / "CHANGELOG.id.md", version)

    en_body = f"# English\n\n{en_summary}\n\n{en_sections}\n\n{INSTALL_EN}".replace("\n\n\n", "\n\n").rstrip() + "\n"
    id_body = f"# Bahasa Indonesia\n\n{id_summary}\n\n{id_sections}\n\n{INSTALL_ID}".replace("\n\n\n", "\n\n").rstrip() + "\n"

    notes = f"{en_body}\n<br>\n\n---\n\n<br>\n\n{id_body}"
    out.write_text(notes, encoding="utf-8")


if __name__ == "__main__":
    main()
