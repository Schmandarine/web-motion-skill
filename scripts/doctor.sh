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
else
  echo "Missing dependencies. Run:"
  echo "  bash $SKILL_DIR/scripts/setup.sh"
fi

# Firefox / WebKit — OPTIONAL. Only needed for cross-engine comparison, and they
# are ~600MB together, so their absence is never an error.
echo
echo "Extra engines (optional — cross-browser comparison only)"
for engine in firefox webkit; do
  FOUND=false
  for dir in "$HOME/Library/Caches/ms-playwright" "$HOME/.cache/ms-playwright"; do
    [ -d "$dir" ] && ls "$dir" 2>/dev/null | grep -q "^$engine" && FOUND=true
  done
  if $FOUND; then
    printf "  \033[32m✓\033[0m %s\n" "$engine"
  else
    printf "  \033[33m–\033[0m %s — not installed\n" "$engine"
  fi
done
printf "  Add both (~600MB): bash %s/scripts/setup.sh --engines\n" "$SKILL_DIR"

# GSAP skills — optional but recommended for the write→record→fix loop
SKILLS_DIR="$(dirname "$SKILL_DIR")"
GSAP_SKILLS=(gsap-core gsap-timeline gsap-scrolltrigger gsap-plugins gsap-utils gsap-react gsap-performance gsap-frameworks)
GSAP_FOUND=()
for skill in "${GSAP_SKILLS[@]}"; do
  [ -d "$SKILLS_DIR/$skill" ] && GSAP_FOUND+=("$skill")
done

echo
echo "GSAP skills (recommended)"
if [ ${#GSAP_FOUND[@]} -eq 0 ]; then
  printf "  \033[33m⚠\033[0m  none installed — web-motion diagnoses animations, but you'll also want\n"
  printf "      the GSAP skills to write and fix the code correctly.\n"
  echo
  echo "  Install:"
  echo "    npx skills add https://github.com/greensock/gsap-skills"
  echo "  Or in Claude Code:"
  echo "    /plugin marketplace add greensock/gsap-skills"
else
  for skill in "${GSAP_FOUND[@]}"; do
    printf "  \033[32m✓\033[0m %s\n" "$skill"
  done
  MISSING_COUNT=$(( ${#GSAP_SKILLS[@]} - ${#GSAP_FOUND[@]} ))
  if [ $MISSING_COUNT -gt 0 ]; then
    printf "  \033[33m⚠\033[0m  %d skill(s) not installed — run: npx skills add https://github.com/greensock/gsap-skills\n" "$MISSING_COUNT"
  fi
fi

echo
$ALL_GOOD && exit 0 || exit 1
