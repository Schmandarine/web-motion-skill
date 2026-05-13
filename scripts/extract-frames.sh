#!/bin/bash
# Extract frames from a video for frame-by-frame inspection.
# Usage: ./extract-frames.sh <input-video> [fps] [output-dir]
#
# Examples:
#   ./extract-frames.sh output.mp4
#   ./extract-frames.sh output.mp4 60 /tmp/my-frames

INPUT="${1:?Usage: extract-frames.sh <input-video> [fps] [output-dir]}"
FPS="${2:-25}"
OUTDIR="${3:-/tmp/anim-frames}"

mkdir -p "$OUTDIR"
ffmpeg -i "$INPUT" -vf "fps=${FPS}" "${OUTDIR}/frame_%04d.png" -y

TOTAL=$(ls "$OUTDIR"/frame_*.png 2>/dev/null | wc -l | tr -d ' ')
echo "Extracted ${TOTAL} frames at ${FPS}fps → ${OUTDIR}"
echo "Duration: $(echo "scale=2; $TOTAL / $FPS" | bc)s"
