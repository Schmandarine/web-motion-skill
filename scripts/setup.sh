#!/bin/bash
# Install all missing dependencies for the web-motion skill.
# Asks consent before large or system-level installs.
set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname)"

echo "Web Motion — setup"
echo "Skill directory: $SKILL_DIR"
echo

# 1. Node — hard requirement, must be present
if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required but not found."
  echo "Install from https://nodejs.org and re-run setup."
  exit 1
fi
echo "✓ node found ($(node --version))"

# 2. ffmpeg — install via system package manager
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo
  echo "ffmpeg is not installed (~80MB)."
  if [ "$OS" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
      read -p "Install via Homebrew? [y/N] " yn
      if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
        brew install ffmpeg
      else
        echo "Skipping ffmpeg. The skill won't work without it."
        exit 1
      fi
    else
      echo "Homebrew not found. Install ffmpeg manually: https://ffmpeg.org/download.html"
      exit 1
    fi
  elif [ "$OS" = "Linux" ]; then
    read -p "Install via apt? [y/N] " yn
    if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
      sudo apt-get update && sudo apt-get install -y ffmpeg
    else
      echo "Skipping ffmpeg. The skill won't work without it."
      exit 1
    fi
  else
    echo "Unsupported OS ($OS). Install ffmpeg manually."
    exit 1
  fi
else
  echo "✓ ffmpeg found"
fi

# 3. Playwright npm package — installed inside the skill dir
if [ ! -d "$SKILL_DIR/node_modules/playwright" ]; then
  echo
  echo "Installing playwright npm package into skill directory..."
  cd "$SKILL_DIR"
  npm install
else
  echo "✓ playwright npm package found"
fi

# 4. Chromium browser — Playwright manages its own browser cache
CHROMIUM_PRESENT=false
for dir in "$HOME/Library/Caches/ms-playwright" "$HOME/.cache/ms-playwright"; do
  [ -d "$dir" ] && ls "$dir" 2>/dev/null | grep -q "chromium" && CHROMIUM_PRESENT=true
done

if ! $CHROMIUM_PRESENT; then
  echo
  echo "Chromium browser is not installed (~300MB download)."
  read -p "Download via Playwright? [y/N] " yn
  if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
    cd "$SKILL_DIR"
    npx playwright install chromium
  else
    echo "Skipping Chromium. Playwright recording won't work without it."
    exit 1
  fi
else
  echo "✓ chromium found"
fi

# 5. Firefox + WebKit — OPTIONAL, cross-engine comparison only.
# Off by default: they are large, slower to drive, and most animation work needs
# exactly one engine. Opt in with `setup.sh --engines`.
WANT_ENGINES=false
for a in "$@"; do [ "$a" = "--engines" ] && WANT_ENGINES=true; done

if $WANT_ENGINES; then
  echo
  echo "Extra engines: Firefox (~271MB) + WebKit (~332MB), ~600MB total on disk."
  echo "Only needed to compare the same animation across browsers."
  read -p "Download both via Playwright? [y/N] " yn
  if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
    cd "$SKILL_DIR"
    npx playwright install firefox webkit
  else
    echo "Skipping. Chromium-only recording still works."
  fi
fi

# Success marker — analyze.sh checks for this
touch "$SKILL_DIR/.installed"

echo
echo "✓ Setup complete."
echo
echo "Try: bash $SKILL_DIR/scripts/analyze.sh http://localhost:5173/your-page.html"
if ! $WANT_ENGINES; then
  echo
  echo "Cross-browser comparison is optional and not installed."
  echo "Add Firefox + WebKit (~600MB): bash $SKILL_DIR/scripts/setup.sh --engines"
fi
