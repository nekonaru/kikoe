#!/usr/bin/env bash
# Measure transcription wall time for a few model and quality combinations.
# Requires the CLI to be built and the models to be cached locally.
set -eu

CLI=${1:-./build/Release/kikoe.exe}
SAMPLE=${2:-third_party/whisper.cpp/samples/jfk.wav}
OUT=${3:-/tmp/kikoe-benchmark}

mkdir -p "$OUT"

now() { python3 -c 'import time; print(time.time())'; }

printf '%-12s %-24s %s\n' MODEL MODE SECONDS
for model in tiny small-q5_1; do
  for extra in "" "--vad" "--vad --quality accurate"; do
    start=$(now)
    if "$CLI" "$SAMPLE" --model "$model" --format txt --outdir "$OUT" $extra >/dev/null 2>&1; then
      end=$(now)
      python3 -c "print('%-12s %-24s %6.2fs' % ('$model', '${extra:-greedy}', $end - $start))"
    else
      printf '%-12s %-24s FAILED\n' "$model" "${extra:-greedy}"
    fi
  done
done
