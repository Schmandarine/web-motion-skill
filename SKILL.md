---
name: web-motion
description: Apply motion design principles to web animations. Use this skill whenever the user wants to add, improve, or review any animation on a website — scroll effects, transitions, hover states, entrance animations, loading states, micro-interactions. Trigger even if the user doesn't say "animation" but describes something moving, appearing, disappearing, or feeling "off" or "robotic" or "too fast/slow".
---

# Web Motion

Motion design principles adapted from Disney's 12 Principles of Animation, applied to the specific constraints of the web — scroll-driven animations, CSS transitions, GSAP timelines, and browser rendering.

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

### Step 1: Capture the video

**If the animation requires real user interaction** (manual scrolling, hover, click):

Run the appropriate script from `scripts/`, then perform the animation in the browser and press `q` to stop:

- macOS: `bash scripts/record-ffmpeg-macos.sh`
- Linux: `bash scripts/record-ffmpeg-linux.sh`

Output: `output.mp4` in the current directory.

**If the animation can be driven by scroll automation** (scroll-scrubbed, no hover needed):

```bash
node scripts/record-playwright.mjs http://localhost:PORT/your-page.html
# optional: node scripts/record-playwright.mjs <url> <totalScrollPx> <steps>
```

Requires `playwright` installed in the project (`npm install playwright`). Output: a `.webm` file in `/tmp/` — the script prints the exact path.

### Step 2: Extract frames

```bash
bash scripts/extract-frames.sh output.mp4
# optional: bash scripts/extract-frames.sh output.mp4 <fps> <output-dir>
```

Default is 25fps — one frame per 40ms, enough to catch timing issues without thousands of files. The script prints total frame count and duration. Use 60fps only if you need sub-frame precision.

### Step 3: Inspect systematically

Read frames as images using the Read tool. Don't just check the first and last — work through the full timeline:

1. Sample every ~10th frame first to map the overall timeline (what's happening when)
2. Once you find the interesting window, read every frame within it
3. Note the exact frame numbers where the animation starts, peaks, and ends
4. Calculate visible duration: `(end_frame - start_frame) / fps = seconds visible`

Look for:
- Animation starting or ending too abruptly (ease not applied or too weak)
- Elements visible for only a handful of frames (wrong end position, exiting immediately)
- Unexpected jumps between frames (competing tweens, wrong label positioning)
- Outgoing animations that don't mirror the incoming feel

Fix the issue in code, re-record, re-extract, and repeat until the frame inspection confirms the desired behavior.

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
