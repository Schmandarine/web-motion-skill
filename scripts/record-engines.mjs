#!/usr/bin/env node
// Record the same page in several browser engines, so the SAME animation can be
// diffed frame-for-frame across Chromium / Firefox / WebKit.
//
// Usage:
//   node record-engines.mjs --url <url> [options]
//
// Options:
//   --engines chromium,firefox,webkit   default: all installed ones
//   --out <dir>                         default /tmp/web-motion-engines-<n>
//   --duration <s>                      total recording time from load (default 5)
//   --scroll <px>                       total wheel distance (default 0 = no scroll)
//   --steps <n>                         wheel steps (default 200)
//   --viewport <WxH>                    default 1440x900
//   --keys <Key,Key,...>                press each key, waiting --dwell between
//   --dwell <s>                         wait after each key (default 2.5)
//   --corner                            park cursor at 40,40 before interacting
//   --headed                            REQUIRED for GPU-heavy pages, see below
//   --reduced                           also record a prefers-reduced-motion pass
//
// Headless vs headed: headless Chromium with video recording on can run a
// rAF loop ~4x slow, and a WebGL-heavy page may never advance at all. If the
// recording looks frozen or the animation never fires, re-run with --headed.
//
// Engines differ in real ways here — video frame pacing is not identical across
// them, so compare SHAPE and ORDER of the animation, not exact frame indices.

import { chromium, firefox, webkit } from 'playwright';

const ENGINES = { chromium, firefox, webkit };

function arg(name, fallback = null) {
  const i = process.argv.indexOf(`--${name}`);
  if (i === -1) return fallback;
  const next = process.argv[i + 1];
  if (!next || next.startsWith('--')) return true; // boolean flag
  return next;
}

const url = arg('url');
if (!url) {
  console.error('Usage: node record-engines.mjs --url <url> [--engines chromium,firefox,webkit]');
  process.exit(1);
}

const wanted = String(arg('engines', 'chromium,firefox,webkit')).split(',').map((s) => s.trim());
const outRoot = arg('out', `/tmp/web-motion-engines-${Date.now()}`);
const duration = parseFloat(arg('duration', '5'));
const scroll = parseInt(arg('scroll', '0'), 10);
const steps = parseInt(arg('steps', '200'), 10);
const dwell = parseFloat(arg('dwell', '2.5'));
const keys = arg('keys') ? String(arg('keys')).split(',').map((s) => s.trim()) : [];
const corner = arg('corner') === true;
const headed = arg('headed') === true;
const reduced = arg('reduced') === true;
const [vw, vh] = String(arg('viewport', '1440x900')).split('x').map(Number);

/** One recording pass. Returns the video path, or null if the engine is absent. */
async function record(name, { reducedMotion } = {}) {
  const type = ENGINES[name];
  if (!type) {
    console.log(`${name}: unknown engine, skipping`);
    return null;
  }

  let browser;
  try {
    browser = await type.launch({ headless: !headed });
  } catch (e) {
    // Missing engine is expected and must not abort the other passes.
    console.log(`${name}: NOT INSTALLED — run setup.sh --engines to add it`);
    return null;
  }

  const dir = `${outRoot}/${name}${reducedMotion ? '-reduced' : ''}`;
  const ctx = await browser.newContext({
    viewport: { width: vw, height: vh },
    deviceScaleFactor: 1,
    recordVideo: { dir, size: { width: vw, height: vh } },
    ...(reducedMotion ? { reducedMotion: 'reduce' } : {}),
  });

  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));

  const t0 = Date.now();
  await page.goto(url, { waitUntil: 'load' });
  await page.waitForTimeout(500);

  // Hovering an interactive element can gate the very animation you want to
  // capture (hover states, melt effects). Park the cursor out of the way.
  if (corner) await page.mouse.move(40, 40);

  if (scroll > 0) {
    for (let i = 0; i < steps; i++) {
      await page.mouse.wheel(0, scroll / steps);
      await page.waitForTimeout(16);
    }
  }

  for (const key of keys) {
    await page.keyboard.press(key);
    await page.waitForTimeout(dwell * 1000);
  }

  const remaining = duration * 1000 - (Date.now() - t0);
  if (remaining > 0) await page.waitForTimeout(remaining);

  const videoPath = await page.video().path();
  await ctx.close();
  await browser.close();

  if (errors.length) console.log(`${name}: page errors — ${errors.join(' | ')}`);
  console.log(`${name}${reducedMotion ? ' (reduced-motion)' : ''}: ${videoPath}`);
  return videoPath;
}

const results = {};
for (const name of wanted) {
  results[name] = await record(name);
  if (reduced) results[`${name}-reduced`] = await record(name, { reducedMotion: true });
}

const ok = Object.entries(results).filter(([, v]) => v);
console.log(`\n${ok.length} recording(s) in ${outRoot}`);
if (!ok.length) process.exit(1);

console.log('\nNext — extract each, then build one comparison sheet:');
for (const [name] of ok) {
  console.log(`  bash extract-frames.sh ${outRoot}/${name}/*.webm 50 ${outRoot}/${name}/frames`);
}
console.log(
  `  bash compare-sheet.sh ${outRoot}/sheet.png 8 ` +
    ok.map(([n]) => `${outRoot}/${n}/frames=${n}`).join(' '),
);
