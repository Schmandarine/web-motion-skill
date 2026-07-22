#!/bin/bash
# Extract frames from a video for frame-by-frame inspection.
# Auto-converts webm → mp4 first (raw webm extraction is flaky with ffmpeg).
#
# Usage: ./extract-frames.sh <input-video> [fps] [output-dir] [start-s] [end-s]
#
# start-s / end-s: optional trim window in seconds — only frames between the
# two timestamps are extracted. Either may be empty/omitted.
#
# Examples:
#   ./extract-frames.sh /tmp/recording.webm
#   ./extract-frames.sh output.mp4 60 /tmp/my-frames
#   ./extract-frames.sh output.mp4 50 /tmp/my-frames 1 4.5

INPUT="${1:?Usage: extract-frames.sh <input-video> [fps] [output-dir] [start-s] [end-s]}"
FPS="${2:-25}"
OUTDIR="${3:-/tmp/anim-frames}"
START="${4:-}"
END="${5:-}"

mkdir -p "$OUTDIR"

# webm direct extraction sometimes errors with "Input/output error" before any
# frames are written. Re-encode to mp4 first — fast with ultrafast preset.
if [[ "$INPUT" == *.webm ]]; then
  CONVERTED="${INPUT%.webm}.mp4"
  if [ ! -f "$CONVERTED" ]; then
    echo "Converting webm → mp4..."
    ffmpeg -i "$INPUT" -c:v libx264 -preset ultrafast -crf 18 "$CONVERTED" -y -loglevel error
  fi
  INPUT="$CONVERTED"
fi

TRIM=()
[ -n "$START" ] && TRIM+=(-ss "$START")
[ -n "$END" ] && TRIM+=(-to "$END")

ffmpeg -i "$INPUT" "${TRIM[@]}" -vf "fps=${FPS}" "${OUTDIR}/frame_%04d.png" -y -loglevel error

TOTAL=$(ls "$OUTDIR"/frame_*.png 2>/dev/null | wc -l | tr -d ' ')
echo "Extracted ${TOTAL} frames at ${FPS}fps → ${OUTDIR}"
echo "Duration: $(echo "scale=2; $TOTAL / $FPS" | bc)s"
