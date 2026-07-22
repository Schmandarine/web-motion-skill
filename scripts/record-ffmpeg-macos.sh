#!/bin/bash
# Screen recording via avfoundation (macOS only).
# Run this, perform the animation in the browser, then press q to stop.
# Output: output.mp4 in the current directory.
#
# Usage: ./record-ffmpeg-macos.sh [device-index]
#
# The screen-capture device index varies per machine (default here: 1).
# If it fails, list available devices and pass the right index:
#   ffmpeg -f avfoundation -list_devices true -i ""

DEVICE="${1:-1}"

ffmpeg -f avfoundation -framerate 60 -i "$DEVICE" \
  -c:v libx264 -preset ultrafast -crf 18 \
  output.mp4
