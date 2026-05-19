#!/bin/bash
# Build a contact sheet (grid of evenly-sampled frames) for fast timeline overview.
# Each tile is labelled with its actual source frame number so you can drill in.
#
# Read this one image first to map when entrance / dwell / exit happen, then
# inspect specific frames individually.
#
# Usage: ./contact-sheet.sh <frames-dir> [output-path] [cols] [rows]
set -e

FRAMES_DIR="${1:?Usage: contact-sheet.sh <frames-dir> [output-path] [cols] [rows]}"
OUTPUT="${2:-${FRAMES_DIR}/contact-sheet.png}"
COLS="${3:-6}"
ROWS="${4:-4}"

TOTAL_NEEDED=$((COLS * ROWS))
TOTAL_FRAMES=$(ls "$FRAMES_DIR"/frame_*.png 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL_FRAMES" -eq 0 ]; then
  echo "No frames found in $FRAMES_DIR"
  exit 1
fi

STEP=$((TOTAL_FRAMES / TOTAL_NEEDED))
[ "$STEP" -lt 1 ] && STEP=1

# Label each sampled frame with its real frame number, then tile them.
# Per-frame ffmpeg calls so the label reflects the source frame, not the tile index.
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

LAST_FRAME=0
for ((i=0; i<TOTAL_NEEDED; i++)); do
  FRAME_NUM=$((1 + i * STEP))
  [ "$FRAME_NUM" -gt "$TOTAL_FRAMES" ] && FRAME_NUM=$TOTAL_FRAMES
  printf -v PADDED "%04d" $FRAME_NUM
  printf -v TILE "%03d" $i
  FRAME_PATH="$FRAMES_DIR/frame_$PADDED.png"
  if [ -f "$FRAME_PATH" ]; then
    ffmpeg -i "$FRAME_PATH" \
      -vf "scale=320:-1,drawtext=text='f${FRAME_NUM}':x=6:y=6:fontsize=18:fontcolor=white:box=1:boxcolor=black@0.7:boxborderw=4" \
      "$TMPDIR/tile_$TILE.png" -y -loglevel error
    LAST_FRAME=$FRAME_NUM
  fi
done

ffmpeg -framerate 1 -i "$TMPDIR/tile_%03d.png" \
  -vf "tile=${COLS}x${ROWS}" \
  "$OUTPUT" -y -loglevel error

echo "Contact sheet: $OUTPUT"
echo "Grid: ${COLS}×${ROWS} = $TOTAL_NEEDED frames, every ${STEP}th from $TOTAL_FRAMES total"
echo "Range: f1 → f${LAST_FRAME}"
