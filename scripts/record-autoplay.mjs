#!/usr/bin/env node
// Record a fixed-duration autoplay animation (no scrolling).
// Usage: node record-autoplay.mjs <url> [seconds] [outDir]
import { chromium } from 'playwright';

const url = process.argv[2];
if (!url) {
  console.error('Usage: node record-autoplay.mjs <url> [seconds] [outDir]');
  process.exit(1);
}
const seconds = parseFloat(process.argv[3] ?? '4');
const outDir = process.argv[4] ?? '/tmp/';

const browser = await chromium.launch();
const ctx = await browser.newContext({
  viewport: { width: 800, height: 800 },
  recordVideo: { dir: outDir, size: { width: 800, height: 800 } },
});
const page = await ctx.newPage();
await page.goto(url);
await page.waitForTimeout(seconds * 1000);
const videoPath = await page.video().path();
await ctx.close();
await browser.close();
console.log('Video saved to:', videoPath);
