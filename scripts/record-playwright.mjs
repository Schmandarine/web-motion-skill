#!/usr/bin/env node
// Automated scroll recording via Playwright.
// Usage: node record-playwright.mjs <url> [totalScrollPx] [steps] [outDir] [durationSec]
//
// durationSec: minimum total recording time measured from page load. If the
// scroll phase finishes earlier, keep recording until this much time has
// passed — needed for page-load animations longer than the default window.
//
// Examples:
//   node record-playwright.mjs http://localhost:5173/demo.html
//   node record-playwright.mjs http://localhost:5173/demo.html 5000 250
//   node record-playwright.mjs http://localhost:5173/demo.html 5000 250 /tmp/run-1
//   node record-playwright.mjs http://localhost:5173/intro.html 0 1 /tmp/run-1 6
//
// Output: a .webm file in outDir (default /tmp/). Playwright names it automatically.
// Convert to mp4 if needed: ffmpeg -i <file>.webm output.mp4
//
// Resolution note: this file imports playwright from a path-relative node_modules.
// Node walks up from this script's directory, so `<skill>/node_modules/playwright`
// is found automatically without any cwd dance.

import { chromium } from 'playwright'

const url = process.argv[2]
if (!url) {
  console.error('Usage: node record-playwright.mjs <url> [totalScrollPx] [steps] [outDir]')
  process.exit(1)
}

const totalScroll = parseInt(process.argv[3] ?? '4000', 10)
const steps = parseInt(process.argv[4] ?? '200', 10)
const outDir = process.argv[5] ?? '/tmp/'
const durationSec = parseFloat(process.argv[6] ?? '0')

const browser = await chromium.launch()
const ctx = await browser.newContext({
  viewport: { width: 1440, height: 900 },
  recordVideo: { dir: outDir, size: { width: 1440, height: 900 } },
})

const page = await ctx.newPage()
const t0 = Date.now()
await page.goto(url)
await page.waitForTimeout(1000)

for (let i = 0; i < steps; i++) {
  await page.mouse.wheel(0, totalScroll / steps)
  await page.waitForTimeout(16)
}

await page.waitForTimeout(500)

// Keep recording until durationSec has passed since page load, so page-load
// animations longer than the scroll phase are captured in full.
if (durationSec > 0) {
  const remaining = durationSec * 1000 - (Date.now() - t0)
  if (remaining > 0) await page.waitForTimeout(remaining)
}
const videoPath = await page.video().path()
await ctx.close()
await browser.close()

console.log('Video saved to:', videoPath)
