#!/bin/bash
# Screen recording via avfoundation (macOS only).
# Run this, perform the animation in the browser, then press q to stop.
# Output: output.mp4 in the current directory.
#
# If device index "2" fails, list available devices first:
#   ffmpeg -f avfoundation -list_devices true -i ""

ffmpeg -f avfoundation -framerate 60 -i "2" \
  -c:v libx264 -preset ultrafast -crf 18 \
  output.mp4
