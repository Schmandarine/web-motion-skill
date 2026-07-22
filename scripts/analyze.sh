#!/bin/bash
# One-shot recording + frame extraction for a scroll-driven or page-load animation.
# Usage: ./analyze.sh <url> [scrollPx] [steps] [--duration <s>] [--start <s>] [--end <s>] [--fps <n>]
#
#   --duration <s>  minimum total recording time in seconds (keeps recording
#                   after the scroll finishes — use for page-load animations
#                   longer than the default ~2.5s window)
#   --start <s>     trim: extract frames starting at this timestamp
#   --end <s>       trim: stop extracting frames at this timestamp
#   --fps <n>       frame extraction rate (default 25)
#
# Examples:
#   ./analyze.sh http://localhost:5173/demo.html
#   ./analyze.sh http://localhost:5173/demo.html 8000 400
#   ./analyze.sh http://localhost:5173/intro.html 0 1 --duration 6        # 6s page-load intro
#   ./analyze.sh http://localhost:5173/intro.html 0 1 --duration 6 --start 1 --end 5 --fps 50
set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$SKILL_DIR/.installed" ]; then
  echo "Web Motion is not set up yet."
  echo "Run: bash $SKILL_DIR/scripts/setup.sh"
  exit 1
fi

DURATION=0
START=""
END=""
FPS=25
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --duration) DURATION="$2"; shift 2 ;;
    --start)    START="$2";    shift 2 ;;
    --end)      END="$2";      shift 2 ;;
    --fps)      FPS="$2";      shift 2 ;;
    *)          POSITIONAL+=("$1"); shift ;;
  esac
done

URL="${POSITIONAL[0]:?Usage: analyze.sh <url> [scrollPx] [steps] [--duration <s>] [--start <s>] [--end <s>] [--fps <n>]}"
SCROLL="${POSITIONAL[1]:-5000}"
STEPS="${POSITIONAL[2]:-250}"

# Unique output dir per run, keyed by timestamp
RUN_DIR="/tmp/web-motion-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

echo "Recording $URL"
echo "  scroll=${SCROLL}px steps=${STEPS} duration=${DURATION}s → $RUN_DIR"
echo

# record-playwright.mjs prints "Video saved to: <path>" on the last line
VIDEO_LINE=$(node "$SKILL_DIR/scripts/record-playwright.mjs" "$URL" "$SCROLL" "$STEPS" "$RUN_DIR" "$DURATION" | tee /dev/stderr | tail -1)
VIDEO_PATH="${VIDEO_LINE#Video saved to: }"

if [ ! -f "$VIDEO_PATH" ]; then
  echo "Recording failed — no video file produced."
  exit 1
fi

echo
echo "Extracting frames..."
bash "$SKILL_DIR/scripts/extract-frames.sh" "$VIDEO_PATH" "$FPS" "$RUN_DIR/frames" "$START" "$END"

echo
echo "Done."
echo "  Video:  $VIDEO_PATH"
echo "  Frames: $RUN_DIR/frames"
echo
echo "Next: generate a contact sheet for fast timeline overview:"
echo "  bash $SKILL_DIR/scripts/contact-sheet.sh $RUN_DIR/frames"
