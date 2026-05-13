#!/bin/bash
# Screen recording via x11grab (Linux only).
# Run this, perform the animation in the browser, then press q to stop.
# Output: output.mp4 in the current directory.
#
# Adjust -s to match your screen resolution and :0 to your display if needed.

ffmpeg -f x11grab -framerate 60 -s 1440x900 -i :0 \
  -c:v libx264 -preset ultrafast -crf 18 \
  output.mp4
