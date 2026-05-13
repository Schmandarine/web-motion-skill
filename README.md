# web-motion

A Claude Code skill that applies Disney's 12 Principles of Animation to web animation — scroll-driven effects, CSS transitions, GSAP timelines, hover states, and micro-interactions.

## What it does

When you're building or debugging an animation and something feels "off" — too fast, too mechanical, too abrupt — this skill gives Claude the mental model to diagnose and fix it using motion design theory rather than trial and error.

Core concepts it brings:
- **The transfer function problem** — why scroll is a linear input and how easing curves compensate for that to make elements feel physical
- **The 12 Principles adapted to web** — Slow In/Out, Anticipation, Stagger, Squash & Stretch, Timing, etc., each with concrete CSS/GSAP examples
- **Scroll-scrubbed animation patterns** — incoming / dwell / outgoing structure, stagger direction, section sizing
- **Frame-by-frame debugging** — record with ffmpeg or Playwright, extract frames, inspect systematically

## Install

Copy the `web-motion/` folder into your Claude skills directory:

```bash
# Global (available in all projects)
cp -r web-motion ~/.claude/skills/

# Project-only
cp -r web-motion .claude/skills/
```

Then reload Claude Code. The skill is available as `/web-motion`.

## Usage

The skill auto-triggers when you're working on anything that moves. You can also invoke it explicitly:

```
/web-motion make these cards animate in from below with a natural feel
```

```
/web-motion this exit animation feels abrupt — the cards just disappear
```

```
/web-motion what ease should I use for a button press?
```

For debugging, Claude will ask before starting a video recording, then inspect every frame autonomously to find the exact frame where things go wrong.

## Requirements

- [Claude Code](https://claude.ai/code)
- For Playwright recording: `npm install playwright` in your project
- For ffmpeg recording: `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux)

## Background

The core insight behind this skill: a `power2.inOut` ease curve is a mathematical approximation of how real objects with mass behave — accelerating from rest, decelerating back to rest. On a scroll-scrubbed animation, that curve acts as a transfer function that converts the mechanical linearity of scroll input into something the eye reads as physical.

This is why two animations that move the same element between the same positions can feel completely different — one natural, one robotic — based purely on the ease curve.
