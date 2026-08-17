#!/usr/bin/env node
// Frame-exact cross-engine comparison via TIMED SCREENSHOTS.
//
// Why not video: Playwright's video recording is not comparable across engines.
// Firefox does not honour the requested video size (the page lands in a corner
// of a differently-scaled canvas), and WebKit pads the head of the file with
// blank frames. Both are fine for eyeballing one engine, useless for diffing
// three. Screenshots are pixel-identical in geometry everywhere.
//
// How it stays exact: one page load per sample. Load → settle → fire trigger →
// wait exactly N ms → single screenshot. Slower than video, but every sample is
// measured from the same zero, so engines line up column-for-column.
//
// Usage:
//   node shoot-engines.mjs --url <url> [options]
//
// Options:
//   --engines chromium,firefox,webkit   default: all three
//   --out <dir>                         default /tmp/web-motion-shots-<n>
//   --offsets 0,60,120,...              ms after the trigger (default 0..700 by 60)
//   --trigger key:ArrowDown|click|wheel:300|none    default none
//   --settle <ms>                       wait after load before triggering (default 800)
//   --clip x,y,w,h                      screenshot only this box
//   --viewport WxH                      default 1440x900
//   --headed                            use a real GPU window
//   --reduced                           extra pass with prefers-reduced-motion
//
// Output: <out>/<engine>/frame_0001.png … numbered in offset order, so
// compare-sheet.sh consumes them directly.

import { chromium, firefox, webkit } from 'playwright';
import { mkdir } from 'node:fs/promises';

const ENGINES = { chromium, firefox, webkit };

function arg(name, fallback = null) {
  const i = process.argv.indexOf(`--${name}`);
  if (i === -1) return fallback;
  const next = process.argv[i + 1];
  if (!next || next.startsWith('--')) return true;
  return next;
}

const url = arg('url');
if (!url) {
  console.error('Usage: node shoot-engines.mjs --url <url> [--engines chromium,firefox,webkit]');
  process.exit(1);
}

const wanted = String(arg('engines', 'chromium,firefox,webkit')).split(',').map((s) => s.trim());
const outRoot = arg('out', `/tmp/web-motion-shots-${Date.now()}`);
const offsets = String(arg('offsets', '0,60,120,180,240,300,360,420,480,540,600,700'))
  .split(',')
  .map(Number);
const trigger = String(arg('trigger', 'none'));
const settle = parseInt(arg('settle', '800'), 10);
const headed = arg('headed') === true;
const reduced = arg('reduced') === true;
const [vw, vh] = String(arg('viewport', '1440x900')).split('x').map(Number);

let clip = null;
if (arg('clip')) {
  const [x, y, width, height] = String(arg('clip')).split(',').map(Number);
  clip = { x, y, width, height };
}

async function fire(page) {
  if (trigger === 'none') return;
  if (trigger === 'click') return page.mouse.click(vw / 2, vh / 2);
  if (trigger.startsWith('key:')) return page.keyboard.press(trigger.slice(4));
  if (trigger.startsWith('wheel:')) return page.mouse.wheel(0, Number(trigger.slice(6)));
  throw new Error(`unknown trigger: ${trigger}`);
}

async function shootEngine(name, { reducedMotion } = {}) {
  const type = ENGINES[name];
  if (!type) {
    console.log(`  ${name}: unknown engine, skipping`);
    return false;
  }

  let browser;
  try {
    browser = await type.launch({ headless: !headed });
  } catch {
    console.log(`  ${name}: NOT INSTALLED — bash setup.sh --engines`);
    return false;
  }

  const dir = `${outRoot}/${name}${reducedMotion ? '-reduced' : ''}`;
  await mkdir(dir, { recursive: true });

  const ctx = await browser.newContext({
    viewport: { width: vw, height: vh },
    deviceScaleFactor: 1,
    ...(reducedMotion ? { reducedMotion: 'reduce' } : {}),
  });

  const problems = [];
  for (let i = 0; i < offsets.length; i++) {
    const page = await ctx.newPage();
    page.on('pageerror', (e) => problems.push(e.message));
    await page.goto(url, { waitUntil: 'load' });
    await page.waitForTimeout(settle);
    await fire(page);
    // The one wait that defines the sample. Everything before it is setup.
    await page.waitForTimeout(offsets[i]);
    await page.screenshot({
      path: `${dir}/frame_${String(i + 1).padStart(4, '0')}.png`,
      ...(clip ? { clip } : {}),
    });
    await page.close();
  }

  await ctx.close();
  await browser.close();

  const uniq = [...new Set(problems)];
  if (uniq.length) console.log(`  ${name}: page errors — ${uniq.join(' | ')}`);
  console.log(`  ${name}${reducedMotion ? ' (reduced)' : ''}: ${offsets.length} shots → ${dir}`);
  return true;
}

console.log(`Sampling ${offsets.length} offsets (${offsets.join(', ')} ms) after "${trigger}"`);
const done = [];
for (const name of wanted) {
  if (await shootEngine(name)) done.push(name);
  if (reduced && (await shootEngine(name, { reducedMotion: true }))) done.push(`${name}-reduced`);
}

if (!done.length) {
  console.error('\nNo engines available.');
  process.exit(1);
}

console.log(`\nNext — one sheet, rows = engines, columns = the SAME time offsets:`);
console.log(
  `  bash compare-sheet.sh ${outRoot}/sheet.png ${offsets.length} ` +
    done.map((n) => `${outRoot}/${n}=${n}`).join(' '),
);
