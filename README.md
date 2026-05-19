# web-motion

A Claude Code skill that **lets agents see web animations** — and gives them the motion design knowledge to fix them.

The hardest part of debugging an animation is articulating what's wrong. "It feels off" is hard to act on. A coding agent that can't actually watch the animation is guessing. This skill solves both problems:

## 1. Vision — agents can read animations frame-by-frame

Bundled scripts record the page with Playwright (or ffmpeg for hover/click flows), extract frames at 25fps, and build a labelled contact sheet — a single grid image that shows the entire animation timeline at a glance, each tile labelled with its source frame number.

The agent reads that one image to map when entrance / dwell / exit happen, then drills into specific frame numbers to find exactly where the animation breaks. The same workflow a motion designer uses reviewing a take in After Effects.

```bash
bash ~/.claude/skills/web-motion/scripts/analyze.sh http://localhost:5173/your-page.html
bash ~/.claude/skills/web-motion/scripts/contact-sheet.sh /tmp/web-motion-*/frames
```

## 2. Judgment — Disney's 12 Principles, adapted for the web

Once the agent can see what's broken, it needs the vocabulary to fix it. The skill loads:

- **The 12 Principles adapted to web** — Slow In/Out, Anticipation, Stagger, Squash & Stretch, Timing, Arc, Appeal — each with concrete CSS / GSAP examples
- **The transfer function problem** — why scroll is a linear input and how easing curves compensate to make elements feel physical
- **Scroll-scrubbed animation patterns** — incoming / dwell / outgoing structure, stagger direction, section sizing
- **Animation safety rules** — `overflow-x: clip`, `box-sizing`, GSAP `from` initial state, percentage transforms
- **An ease selection table** — what curve to use for entrance, exit, button press, scatter, settle, bounce

Without vision the agent guesses. Without the principles "it feels off" stays unactionable. Together: watch the take → name the violated principle → write the fix → re-record to verify.

## Install

```bash
git clone https://github.com/Schmandarine/web-motion-skill ~/.claude/skills/web-motion
bash ~/.claude/skills/web-motion/scripts/setup.sh
```

`setup.sh` is platform-aware and asks consent before each install:
- ffmpeg (~80MB via Homebrew on macOS, apt on Linux)
- playwright npm package (installed locally inside the skill directory — no project pollution)
- Chromium browser (~300MB via Playwright)

A `.installed` marker is written on success. Future runs skip the check.

Reload Claude Code. The skill auto-triggers on animation tasks, or can be invoked explicitly via `/web-motion`.

## Usage

The skill auto-triggers when you're working on anything that moves:

```
make these cards animate in from below with a natural feel
```
```
this exit animation feels abrupt — the cards just disappear
```
```
what ease should I use for a button press?
```

For frame-by-frame debugging, Claude will ask before starting a recording, then use the bundled scripts to capture, extract, and inspect:

```bash
bash ~/.claude/skills/web-motion/scripts/analyze.sh http://localhost:5173/your-page.html
bash ~/.claude/skills/web-motion/scripts/contact-sheet.sh /tmp/web-motion-*/frames
```

The contact sheet shows the entire timeline as a single labelled grid image — Claude reads it once to map the animation, then drills into specific frame numbers to find issues.

## Scripts

| Script | Purpose |
|---|---|
| `doctor.sh` | Check whether all dependencies are installed |
| `setup.sh` | Install missing dependencies (consent-based) |
| `analyze.sh` | One-shot: record scroll animation + extract frames |
| `contact-sheet.sh` | Build a labelled grid of evenly-sampled frames |
| `record-playwright.mjs` | Playwright auto-scroll recording (called by analyze.sh) |
| `record-ffmpeg-macos.sh` | Manual screen recording on macOS (for hover/click animations) |
| `record-ffmpeg-linux.sh` | Manual screen recording on Linux |
| `extract-frames.sh` | Extract frames from a video, auto-converts webm → mp4 |

## Background

The core insight behind this skill: a `power2.inOut` ease curve is a mathematical approximation of how real objects with mass behave — accelerating from rest, decelerating back to rest. On a scroll-scrubbed animation, that curve acts as a transfer function that converts the mechanical linearity of scroll input into something the eye reads as physical.

This is why two animations that move the same element between the same positions can feel completely different — one natural, one robotic — based purely on the ease curve.

## Requirements

- [Claude Code](https://claude.ai/code)
- Node.js (only hard prerequisite — `setup.sh` installs the rest)
- macOS or Linux (Windows untested)
