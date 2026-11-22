#!/usr/bin/env bash
# End-to-end smoke test: download a small model and transcribe the JFK sample.
# Used by CI (Ubuntu) so a merge is never green on --help alone.
set -euo pipefail

BIN="${1:-./build/kikoe}"
WAV="third_party/whisper.cpp/samples/jfk.wav"
MODEL_NAME="tiny-q5_1"
CACHE="$HOME/.cache/kikoe/models"
MODEL="$CACHE/ggml-tiny-q5_1.bin"

if [ ! -f "$MODEL" ]; then
  "$BIN" --download-model "$MODEL_NAME" >/dev/null
fi

OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
"$BIN" "$WAV" --model "$MODEL" --lang en --format txt -o "$OUT" >/dev/null 2>&1
cat "$OUT"
grep -qi "fellow americans" "$OUT"
echo "end-to-end transcription OK"
