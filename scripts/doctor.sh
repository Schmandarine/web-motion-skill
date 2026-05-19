#!/bin/bash
# Check whether all web-motion dependencies are installed.
# Exits 0 if everything's ready, 1 if anything is missing.
# Run setup.sh to install missing pieces.

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALL_GOOD=true

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    printf "  \033[32m✓\033[0m %s\n" "$name"
  else
    printf "  \033[31m✗\033[0m %s — missing\n" "$name"
    ALL_GOOD=false
  fi
}

echo "Web Motion — dependency check"
echo

check "node"        "command -v node"
check "ffmpeg"      "command -v ffmpeg"
check "playwright"  "[ -d '$SKILL_DIR/node_modules/playwright' ]"

# Chromium lives in playwright's per-user cache, not in node_modules
CHROMIUM_OK=false
if [ -d "$HOME/Library/Caches/ms-playwright" ]; then
  ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -q "chromium" && CHROMIUM_OK=true
fi
if [ -d "$HOME/.cache/ms-playwright" ]; then
  ls "$HOME/.cache/ms-playwright" 2>/dev/null | grep -q "chromium" && CHROMIUM_OK=true
fi
if $CHROMIUM_OK; then
  printf "  \033[32m✓\033[0m chromium\n"
else
  printf "  \033[31m✗\033[0m chromium — missing\n"
  ALL_GOOD=false
fi

echo
if $ALL_GOOD; then
  echo "Ready."
  exit 0
else
  echo "Missing dependencies. Run:"
  echo "  bash $SKILL_DIR/scripts/setup.sh"
  exit 1
fi
