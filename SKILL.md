---
name: web-motion
description: Closes the agentic coding loop for web animation. Lets Claude scroll the user's page while recording it (Playwright), extract frames, build a labelled contact sheet, and reason about timing/easing/trajectory frame-by-frame — plus motion design principles (Disney's 12, adapted for web, GSAP, CSS, scroll input) to name and fix what's wrong. Use whenever the user wants to add, improve, debug, or review any animation — scroll effects, transitions, hover states, entrance/exit, loading states, micro-interactions. Trigger even if the user doesn't say "animation" but describes something moving, appearing, disappearing, or feeling "off" or "robotic" or "too fast/slow".
---

# Web Motion

This skill closes the agentic coding loop for web animation. Without it, you write animation code blind — you can't watch what you just produced, so you rely on the user to describe what feels wrong. With it you get both halves of the loop:

1. **Vision** — bundled scripts record the page with Playwright (or ffmpeg for hover/click flows), extract frames at 25fps, and build a labelled contact sheet. You read those images directly and reason about timing, easing, and trajectory the way a motion designer reviews a take.
2. **Judgment** — Disney's 12 Principles of Animation, adapted for the constraints of the web (scroll input, GSAP timelines, CSS transitions, browser rendering). Once you can see what's broken, the principles name what's wrong and point at the fix.

The combination is what matters. Without vision, you guess about an animation you can't perceive. Without the principles, *"it feels off"* stays unactionable. Together: watch the take → name the violated principle → write the fix → re-record to verify.

## Works with the Official GSAP Skills

This skill handles **vision and judgment** — recording the page, reading frames, naming what's wrong. The [official GSAP skills](https://github.com/greensock/gsap-skills) handle **API correctness** — writing GSAP code the right way (timelines, ScrollTrigger, plugins, React, performance).

Together they close the full loop:

1. **Write** — use the GSAP skills to produce correct animation code
2. **Record** — this skill records and extracts frames
3. **Diagnose** — this skill names the violated motion principle
4. **Fix** — back to GSAP skills to edit the code
5. **Verify** — re-record and confirm

When fixing animation code mid-session, reach for the appropriate GSAP skill:

| Task | GSAP skill |
|---|---|
| Tweens, easing, stagger | `gsap-core` |
| Timeline sequencing, position parameter | `gsap-timeline` |
| ScrollTrigger, pinning, scrub | `gsap-scrolltrigger` |
| SplitText, ScrollSmoother, Flip, plugins | `gsap-plugins` |
| React / Next.js | `gsap-react` |
| Performance, jank, will-change | `gsap-performance` |
| Vue, Svelte | `gsap-frameworks` |

Install: `npx skills add https://github.com/greensock/gsap-skills`  
Or in Claude Code: `/plugin marketplace add greensock/gsap-skills`

## The Core Problem: Linear Input, Non-Linear Perception

The underlying idea: real objects have mass, so they never start or stop instantaneously. They accelerate from rest and decelerate back to rest. A `power2.inOut` curve is literally a mathematical approximation of that physical behavior.

What makes this especially important for scroll-scrubbed animations is the input problem:

- **Scroll is a linear input** — the user drags through progress at roughly constant speed
- **Human perception of movement is non-linear** — we judge naturalness by acceleration curves, not constant velocity

So the easing curve acts as a **transfer function** between the linear scroll input and the non-linear animation output. Strong eases (`power3`, `power4`) compensate harder for the mechanical nature of scroll — the object stays still longer, then commits fast. The user's hand moves at a constant rate but the thing on screen feels like it has weight and momentum.

Studios known for this pattern (Resn, Active Theory, Locomotive) often layer it further:
1. A smooth scroll library (Lenis) adds momentum to the scroll itself
2. GSAP scrub + strong ease adds momentum to the element within the scroll
3. The double-layering makes everything feel heavy and deliberate

The short version: you're using the ease curve to **fake physics on a fundamentally physics-free input device**. It's why `power2.inOut` looks natural and a raw `scrub: true` with no ease looks mechanical — even though both move the same start and end positions.

**Trade-off — smooth scroll libraries:** The double-layering approach (Lenis + GSAP ease) produces a heavier, more deliberate feel that some products want. The downside is added input latency that can read as laggy on fast machines or for users who prefer snappy, native-feeling scroll. Both approaches are valid — choose based on the product's personality. If in doubt, ask the user which they prefer before reaching for Lenis.

---

## The 12 Principles, Web-Adapted

### 1. Slow In / Slow Out
Real objects have mass. They accelerate from rest and decelerate back to rest — they never start or stop instantaneously.

**Web:** Use `ease-in-out` curves (`power2.inOut`, `cubic-bezier(0.4, 0, 0.2, 1)`) for most movements. For scroll-scrubbed animations, this principle is critical — it's the transfer function that makes linear scroll feel physical. For outgoing animations that exit the viewport, `inOut` still works because the deceleration happens off-screen.

### 2. Anticipation
A small preparatory motion in the opposite direction before the main action signals what's about to happen and adds energy.

**Web:** Button presses scale down slightly before triggering. A card tilts slightly before flying off. A drawer handle jiggles before the drawer opens. Keep anticipation subtle (0.05–0.1 scale, 3–8deg rotation) — it should register subconsciously, not literally.

### 3. Follow Through & Overlapping Action
Parts of a system continue moving after the main body stops. Actions in a group start and end at slightly different times rather than all moving together.

**Web:** Stagger. If multiple elements animate, offset their start times (`stagger: 0.08` in GSAP). Elements shouldn't all arrive at exactly the same frame. A reversed stagger (`stagger: -0.12`) makes the rightmost/last element lead, which often looks more natural for elements entering from below or left.

### 4. Squash & Stretch
Objects deform to show mass and flexibility — they compress on impact, elongate when moving fast.

**Web:** `scale(0.95)` on button press (squash). Spring eases that overshoot target and bounce back (stretch). `scaleY` compression on a bouncing loader. Avoid for UI components that must feel rigid/professional — use for playful, expressive moments only.

### 5. Staging
Clear presentation of the idea. Composition and timing direct the user's eye to what matters.

**Web:** Entrance animations should guide reading order, not fight it. Animate the headline first, body text second, CTA last. Use `overflow: hidden` on containers to create reveal effects without layout shift. Don't animate 6 things at once — stage them so attention lands where you want it.

### 6. Secondary Action
Additional actions that support and enrich the main action without competing with it.

**Web:** Icon rotates while its parent card slides in. Text fades while its container translates. A checkmark draws itself after a form submits. Secondary actions should feel like natural consequences of the primary action — if they draw attention away from the main event, they're too prominent.

### 7. Timing
Duration determines perceived weight, speed, and mood.

**Web defaults:**
- `100–150ms` — immediate feedback (button press, focus ring, hover state)
- `200–300ms` — UI transitions (dropdown open, tooltip appear, tab switch)
- `400–600ms` — meaningful transitions (page section change, modal enter)
- `600ms+` — emphasis or storytelling (hero entrance, scroll-driven reveals)

Never animate the same property twice in overlapping durations — the browser (and the eye) can't track it.

### 8. Exaggeration
Push the action beyond realism to clarify intent and add personality.

**Web:** Spring eases that overshoot by 10–15% before settling. Rotation angles on a scatter effect pushed to ±60–70deg instead of ±20deg. Scale on hover pushed to 1.08 instead of 1.02. Exaggeration should feel playful, not broken — calibrate to the personality of the product.

### 9. Arc
Most natural movements follow curved paths rather than straight lines. Straight-line motion feels mechanical and robotic.

**Web:** When an element moves diagonally, animate `x` and `y` with slightly different eases so the path curves. Cards "thrown" off screen should follow arcs, not straight vectors. In GSAP, `motionPath` plugin handles literal arcs; for simple cases, offset ease timings create the illusion.

### 10. Depth (from Solid Drawing)
Objects exist in 3D space with weight, volume, and shadow. In flat UI, depth is simulated.

**Web:** Parallax (foreground moves faster than background). `perspective` + `rotateX/Y` for card tilt on hover. Shadows that shift as elements lift (`box-shadow` scaling on hover). z-index layering that's reinforced by scale — elements "above" others scale slightly larger on entrance.

### 11. Pose to Pose vs. Straight Ahead
Two approaches: define key states and interpolate between them (pose to pose), or simulate physics frame by frame (straight ahead).

**Web:** CSS transitions and GSAP tweens are pose to pose — define start and end, let the browser interpolate. Physics engines (Matter.js, Cannon.js) or spring simulations are straight ahead. Most UI animation is pose to pose. Use straight ahead only when the motion is too complex or unpredictable to keyframe — falling debris, cloth, fluid.

### 12. Appeal (Motion Language Consistency)
The overall animation system should feel coherent and have personality. Every motion choice communicates something about the product.

**Web:** Establish a consistent easing vocabulary and stick to it. If entrance animations use `power2.inOut`, exit animations should too — they're the same object, same physics. Don't mix spring eases with linear eases on the same component. Fast, snappy motion says confident and modern. Slow, heavy motion says thoughtful and premium. Both are valid — be intentional and consistent.

---

## Animation Safety Rules

Before writing any animation code, check these — they're easy to miss and cause broken layouts:

**Horizontal overflow** — GSAP `from` animations with `x` transforms, or any element wider than the viewport, will create a horizontal scrollbar. Always add to the page root:
```css
html { overflow-x: clip; }
```
`clip` (not `hidden`) is preferred — it doesn't create a new stacking context and doesn't interfere with `position: fixed` elements.

**box-sizing** — If `box-sizing: border-box` is not set globally, padding adds to `max-width`, making containers wider than intended. Always confirm the project has:
```css
*, *::before, *::after { box-sizing: border-box; }
```

**GSAP `from` initial state** — `gsap.from()` immediately applies the start state. If that start state is off-screen (e.g., `y: '100%'`, `x: '-100%'`), the element is invisible before ScrollTrigger fires. Use `gsap.fromTo()` or set `immediateRender: false` if this causes layout flash.

**Percentage transforms vs pixel values** — `x: '100%'` in GSAP means 100% of the element's own width, not the viewport. For an element 800px wide, that's 800px off to the right — well outside the viewport. Use pixel values when you need precise control.

---

## Scroll-Scrubbed Animation Patterns

When building scroll-driven animations (GSAP ScrollTrigger or CSS scroll-timeline):

**Structure:**
1. **Incoming phase** — element enters with strong ease (Principle 1). Duration ~25% of scroll range.
2. **Dwell** — element holds still. Leave a gap in the timeline (no tweens = nothing moves). Duration ~40–50% of scroll range.
3. **Outgoing phase** — element exits with matching ease (mirror of incoming). Duration ~25% of scroll range.

**Key rules:**
- Use the same ease family for incoming and outgoing — they're the same object with the same physics
- Size the section height to give each phase enough scroll distance to feel intentional
- `scrub: true` (no number) ties 1:1 to scroll. `scrub: 1` adds 1s lag — use only when that lag reads as deliberate weight, not as latency

**Incoming stagger:** reversed (`stagger: -0.12`) so elements arrive in the natural reading order (left/top first).  
**Outgoing stagger:** forward (`stagger: 0.07`) so the first element leads the exit.

---

## Animation Debugging: Frame-by-Frame Inspection

When an animation feels wrong but it's hard to articulate why (too fast, wrong timing, disappears too quickly, feels abrupt), the most reliable method is to capture a video and inspect every frame as an image. This lets you find the exact frame where things go wrong and measure visible durations precisely.

**Always ask the user before starting a recording.** Something like: "Want me to record the animation so I can inspect it frame by frame?" — never start recording silently.

### First-time setup

Before recording, check that the skill's dependencies are installed:

```bash
bash ~/.claude/skills/web-motion/scripts/doctor.sh
```

If anything is missing, run setup once (it asks consent for system installs):

```bash
bash ~/.claude/skills/web-motion/scripts/setup.sh
```

This installs ffmpeg (via Homebrew on macOS, apt on Linux), the playwright npm package inside the skill directory, and the Chromium browser (~300MB). A `.installed` marker is written on success so future runs skip the check.

### Step 1: Record and extract — one command

For scroll-driven animations (the common case), run:

```bash
bash ~/.claude/skills/web-motion/scripts/analyze.sh http://localhost:PORT/your-page.html
# optional: analyze.sh <url> <totalScrollPx> <steps> [--duration <s>] [--start <s>] [--end <s>] [--fps <n>]
```

This records the page with Playwright auto-scrolling, converts to mp4, and extracts frames at 25fps. Output lands in `/tmp/web-motion-<timestamp>/frames/`.

Flags:
- `--duration <s>` — minimum total recording time from page load. The default window is only ~2.5s (1s settle + scroll + 0.5s tail); **for page-load animations, always pass a duration comfortably longer than the full animation**, e.g. `analyze.sh <url> 0 1 --duration 6`.
- `--start <s>` / `--end <s>` — trim the frame-extraction window, so dead time before/after the animation doesn't dilute the contact sheet.
- `--fps <n>` — extraction framerate (default 25). Raise to 50 to inspect fast easings frame-by-frame.

**For pure page-load animations** where the first ~1s matters (analyze.sh waits 1s after load before its scroll phase, so the very start of an intro can be missed), record with the autoplay recorder instead — it captures from t=0 with no scrolling and no pre-wait — then extract frames manually:

```bash
node ~/.claude/skills/web-motion/scripts/record-autoplay.mjs <url> [seconds] [outDir]
bash ~/.claude/skills/web-motion/scripts/extract-frames.sh <video.webm> [fps] [outDir] [start-s] [end-s]
```

**For animations that need real user interaction** (hover, click, manual scroll), use the manual ffmpeg scripts instead:

```bash
bash ~/.claude/skills/web-motion/scripts/record-ffmpeg-macos.sh    # or -linux.sh
bash ~/.claude/skills/web-motion/scripts/extract-frames.sh output.mp4
```

### Step 2: Map the timeline with a contact sheet

Before reading individual frames, build a contact sheet — a 6×4 grid of evenly-sampled frames, each labelled with its source frame number:

```bash
bash ~/.claude/skills/web-motion/scripts/contact-sheet.sh /tmp/web-motion-*/frames
```

Read the resulting `contact-sheet.png` once. You'll see the entire animation timeline at a glance — entrance, dwell, and exit phases are immediately visible, and the frame-number labels tell you exactly where to drill in.

### Step 3: Drill into the interesting window

Once the contact sheet has told you roughly when each phase happens, read individual frames within those windows:

1. Use the contact sheet to identify candidate frame numbers (e.g., "entrance starts around f60, dwell at f80–f115, exit around f120")
2. Read every 2–3 frames within those windows using the Read tool
3. Note the exact frame numbers where the animation starts, peaks, and ends
4. Calculate visible duration: `(end_frame - start_frame) / fps = seconds visible`

Look for:
- Animation starting or ending too abruptly (ease not applied or too weak)
- Elements visible for only a handful of frames (wrong end position, exiting immediately)
- Unexpected jumps between frames (competing tweens, wrong label positioning)
- Outgoing animations that don't mirror the incoming feel
- Containers clipping elements during scatter/exit (`overflow: hidden` on a parent)

Fix the issue in code, re-run `analyze.sh`, regenerate the contact sheet, and repeat until the frame inspection confirms the desired behavior.

### Recording gotchas that cost real time

- **Headless throttles rAF.** With video recording on, headless Chromium can run an animation loop ~4× slow, and a WebGL-heavy page may never advance at all. If a recording looks frozen or an animation never fires, re-run headed (`chromium.launch({ headless: false })`) for the real GPU and real-time frames.
- **Window scrolling is not wheel input.** Pages that listen for `wheel` on a container (or use a custom scroll hijack) ignore `window.scrollBy`. Use `page.mouse.wheel()`.
- **Hover can gate the thing you want to record.** Melt/hover states, drag holds and "is the user interacting" flags often suppress the transition. Park the cursor out of the way (`page.mouse.move(40, 40)`) before triggering. If a page "won't animate", suspect an input gate before suspecting the recorder.
- **Full-page contact sheets are too coarse for short animations.** A 0.7s morph in a 1440px frame is a few dark pixels. Crop to the element (`crop=W:H:X:Y`) before tiling.

---

## Cross-Browser Comparison (opt-in — only when the user asks)

**This is not part of the normal loop. Do not run it, and do not install anything for it, unless the user explicitly asks to check other browser engines** — "does this work in Safari", "check Firefox", "test across browsers", or similar. The default workflow stays exactly as above: **Chromium + video + contact sheet.**

Firefox and WebKit are **not installed by default** and are **~600MB together** (Firefox ~271MB, WebKit ~332MB). Never install them silently, and never install them on your own initiative.

If you happen to notice the animation depends on something engines historically disagree on — **SVG filters, `feColorMatrix` thresholds, CSS `filter`/`backdrop-filter`, `mix-blend-mode`, large blurs, `clip-path`, scroll-timeline** — you may mention it in one line so the user can decide. Then carry on with the Chromium loop. Do not install, do not run, do not wait for an answer:

> Worth noting: this leans on an SVG filter threshold, which is where engines diverge most. Say the word if you want a cross-engine check — it needs a ~600MB one-time install.

Nothing here applies to plain transforms and opacity. Those agree everywhere.

Install, once the user has asked (prompts before downloading):

```bash
bash ~/.claude/skills/web-motion/scripts/setup.sh --engines
```

### Use screenshots, NOT video, across engines

Playwright video is not comparable between engines: **Firefox ignores the requested video size** (the page lands in a corner of a differently-scaled canvas) and **WebKit pads the head of the file with blank frames**. Both are fine for one engine, useless for diffing three.

`shoot-engines.mjs` samples timed screenshots instead — one page load per sample, so every engine is measured from the same zero and geometry is pixel-identical:

```bash
S=~/.claude/skills/web-motion/scripts

node $S/shoot-engines.mjs --url http://localhost:5173/demo.html \
  --engines chromium,firefox,webkit \
  --trigger key:ArrowDown --settle 800 \
  --offsets 0,120,240,360,480,600 \
  --clip 70,395,440,80

bash $S/compare-sheet.sh /tmp/<out>/sheet.png 6 \
  /tmp/<out>/chromium=chromium /tmp/<out>/firefox=firefox /tmp/<out>/webkit=webkit
```

Triggers: `none`, `click`, `key:<Key>`, `wheel:<px>`. Add `--reduced` for an extra `prefers-reduced-motion` pass per engine — the cheapest way to confirm a reduced-motion path actually snaps.

`compare-sheet.sh` puts **one row per engine, one column per offset**. Read down each column: a blank cell where the others show the effect is a broken engine, and a shifted-but-identical sequence is just timing. It also works for one engine across two code versions (before/after a fix).

`record-engines.mjs` does the video equivalent if you specifically want motion blur/pacing per engine — but read the caveat above first.

### What this actually catches

A real example. A gooey text morph (CSS blur under an SVG `feColorMatrix` alpha threshold) at `cut: 0.33` looked perfect in Chromium and WebKit. The comparison sheet showed Firefox rendering **nothing at all** for 120–600ms — Firefox's thresholded output is far thinner for the same blurred input, so no pixel cleared the cut. It read as a blink, not a morph. Dropping `cut` to `0.18` made all three identical. Chromium-only testing would have shipped it broken in Firefox.

---

## Quick Reference: Ease Selection

| Situation | Ease |
|---|---|
| Element entering viewport | `power2.inOut` or `power3.inOut` |
| Element exiting viewport | `power2.inOut` (deceleration happens off-screen) |
| Button / immediate feedback | `power2.out` (fast start, settles) |
| Object being thrown / launched | `power3.in` (accelerates into exit) |
| Object landing / settling | `power3.out` (decelerates into rest) |
| Playful bounce / elastic | `elastic.out(1, 0.5)` or `back.out(1.7)` |
| Mechanical / deliberate | `power1.inOut` |
