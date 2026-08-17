#!/bin/bash
# Build one comparison sheet from several frame directories — typically the same
# animation recorded in different browser engines.
#
# One ROW per source, one COLUMN per sampled moment, so divergence between
# engines shows up as a vertical mismatch you can spot at a glance.
#
# Usage:
#   bash compare-sheet.sh <out.png> <columns> <dir=label> [dir=label ...] [--crop WxH+X+Y] [--range A-B]
#
# Examples:
#   bash compare-sheet.sh /tmp/x/sheet.png 8 /tmp/x/chromium/frames=chromium /tmp/x/firefox/frames=firefox
#   bash compare-sheet.sh /tmp/x/sheet.png 10 /tmp/x/chromium/frames=chrome --crop 440x80+70+395 --range 90-140
#
# --crop  crop each frame before tiling. A full 1440px frame is far too coarse
#         to judge a 0.7s morph — crop to the element that matters.
# --range limit sampling to frames A..B (inclusive).
set -e

OUT="$1"
COLS="$2"
shift 2 || { echo "Usage: compare-sheet.sh <out.png> <columns> <dir=label> ..." >&2; exit 1; }

CROP=""
RANGE=""
SOURCES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --crop)  CROP="$2"; shift 2 ;;
    --range) RANGE="$2"; shift 2 ;;
    *)       SOURCES+=("$1"); shift ;;
  esac
done

[ ${#SOURCES[@]} -eq 0 ] && { echo "No source directories given." >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not found. Run setup.sh." >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ffmpeg's crop filter wants crop=W:H:X:Y; accept the friendlier WxH+X+Y too.
CROP_FILTER=""
if [ -n "$CROP" ]; then
  CW="${CROP%%x*}"; REST="${CROP#*x}"
  CH="${REST%%+*}"; REST="${REST#*+}"
  CX="${REST%%+*}"; CY="${REST#*+}"
  CROP_FILTER="crop=${CW}:${CH}:${CX}:${CY},"
fi

STRIPS=()
ROW=0

for SRC in "${SOURCES[@]}"; do
  DIR="${SRC%%=*}"
  LABEL="${SRC#*=}"
  [ "$LABEL" = "$DIR" ] && LABEL="$(basename "$(dirname "$DIR")")"

  if [ ! -d "$DIR" ]; then
    echo "  ⚠ $LABEL — no such directory: $DIR (skipping)"
    continue
  fi

  # shellcheck disable=SC2207
  FRAMES=($(ls "$DIR"/frame_*.png 2>/dev/null | sort))
  TOTAL=${#FRAMES[@]}
  if [ "$TOTAL" -eq 0 ]; then
    echo "  ⚠ $LABEL — no frame_*.png in $DIR (skipping)"
    continue
  fi

  FIRST=0
  LAST=$((TOTAL - 1))
  if [ -n "$RANGE" ]; then
    A="${RANGE%%-*}"; B="${RANGE#*-}"
    FIRST=$((A - 1)); LAST=$((B - 1))
    [ "$FIRST" -lt 0 ] && FIRST=0
    [ "$LAST" -gt $((TOTAL - 1)) ] && LAST=$((TOTAL - 1))
  fi

  SPAN=$((LAST - FIRST))
  [ "$SPAN" -lt 0 ] && SPAN=0

  for ((c = 0; c < COLS; c++)); do
    if [ "$COLS" -gt 1 ]; then
      IDX=$((FIRST + SPAN * c / (COLS - 1)))
    else
      IDX=$FIRST
    fi
    SRC_FRAME="${FRAMES[$IDX]}"
    NUM="$(basename "$SRC_FRAME" .png | sed 's/frame_//')"
    # Label every cell with engine + real frame number, so a mismatch is
    # traceable back to a specific frame without re-deriving the index.
    ffmpeg -loglevel error -y -i "$SRC_FRAME" \
      -vf "${CROP_FILTER}drawtext=text='${LABEL} f${NUM}':x=4:y=4:fontsize=20:fontcolor=red:box=1:boxcolor=white@0.75:boxborderw=3" \
      "$TMP/r${ROW}_$(printf '%03d' "$c").png"
  done

  ffmpeg -loglevel error -y -pattern_type glob -i "$TMP/r${ROW}_*.png" \
    -vf "tile=${COLS}x1" "$TMP/strip_${ROW}.png"
  STRIPS+=("$TMP/strip_${ROW}.png")
  echo "  ✓ $LABEL — $TOTAL frames, sampled $COLS"
  ROW=$((ROW + 1))
done

[ ${#STRIPS[@]} -eq 0 ] && { echo "Nothing to compare." >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"

if [ ${#STRIPS[@]} -eq 1 ]; then
  cp "${STRIPS[0]}" "$OUT"
else
  ARGS=()
  for s in "${STRIPS[@]}"; do ARGS+=(-i "$s"); done
  ffmpeg -loglevel error -y "${ARGS[@]}" \
    -filter_complex "vstack=inputs=${#STRIPS[@]}" "$OUT"
fi

echo
echo "Comparison sheet: $OUT"
echo "Rows = sources in the order given, columns = time. Compare the SHAPE and"
echo "ORDER of the animation down each column — engines do not pace video frames"
echo "identically, so exact frame numbers will not line up."
