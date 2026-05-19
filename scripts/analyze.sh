#!/bin/bash
# One-shot recording + frame extraction for a scroll-driven animation.
# Usage: ./analyze.sh <url> [scrollPx] [steps]
#
# Examples:
#   ./analyze.sh http://localhost:5173/demo.html
#   ./analyze.sh http://localhost:5173/demo.html 8000 400
set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$SKILL_DIR/.installed" ]; then
  echo "Web Motion is not set up yet."
  echo "Run: bash $SKILL_DIR/scripts/setup.sh"
  exit 1
fi

URL="${1:?Usage: analyze.sh <url> [scrollPx] [steps]}"
SCROLL="${2:-5000}"
STEPS="${3:-250}"

# Unique output dir per run, keyed by timestamp
RUN_DIR="/tmp/web-motion-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

echo "Recording $URL"
echo "  scroll=${SCROLL}px steps=${STEPS} → $RUN_DIR"
echo

# record-playwright.mjs prints "Video saved to: <path>" on the last line
VIDEO_LINE=$(node "$SKILL_DIR/scripts/record-playwright.mjs" "$URL" "$SCROLL" "$STEPS" "$RUN_DIR" | tee /dev/stderr | tail -1)
VIDEO_PATH="${VIDEO_LINE#Video saved to: }"

if [ ! -f "$VIDEO_PATH" ]; then
  echo "Recording failed — no video file produced."
  exit 1
fi

echo
echo "Extracting frames..."
bash "$SKILL_DIR/scripts/extract-frames.sh" "$VIDEO_PATH" 25 "$RUN_DIR/frames"

echo
echo "Done."
echo "  Video:  $VIDEO_PATH"
echo "  Frames: $RUN_DIR/frames"
echo
echo "Next: generate a contact sheet for fast timeline overview:"
echo "  bash $SKILL_DIR/scripts/contact-sheet.sh $RUN_DIR/frames"
