#!/usr/bin/env python3
"""Build a bilingual release-notes file from CHANGELOG.md and CHANGELOG.id.md.

Usage: build_release_notes.py v1.0.0 [output-file]
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def extract(path: Path, tag: str) -> str:
    text = path.read_text(encoding="utf-8")
    for candidate in (tag, tag.lstrip("vV")):
        match = re.search(rf"## \[{re.escape(candidate)}\](.*?)(?=\n## |\Z)", text, re.S)
        if match:
            body = match.group(1).strip()
            # Drop the "- YYYY-MM-DD" trailing the version heading.
            body = re.sub(r"^-\s*\d{4}-\d{2}-\d{2}\s*", "", body).strip()
            return body
    sys.exit(f"No section for tag '{tag}' found in {path}")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("usage: build_release_notes.py <tag> [output]")
    tag = sys.argv[1]
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("RELEASE_NOTES.md")

    en = extract(ROOT / "CHANGELOG.md", tag)
    idn = extract(ROOT / "CHANGELOG.id.md", tag)

    notes = f"""{en}

---

{idn}
"""
    out.write_text(notes, encoding="utf-8")


if __name__ == "__main__":
    main()
