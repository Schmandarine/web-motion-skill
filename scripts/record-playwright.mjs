#!/usr/bin/env node
// Automated scroll recording via Playwright.
// Usage: node record-playwright.mjs <url> [totalScrollPx] [steps]
//
// Examples:
//   node record-playwright.mjs http://localhost:5173/demo.html
//   node record-playwright.mjs http://localhost:5173/demo.html 5000 250
//
// Output: a .webm file in /tmp/ (Playwright names it automatically).
// Convert to mp4 if needed: ffmpeg -i /tmp/<file>.webm output.mp4

import { chromium } from 'playwright'

const url = process.argv[2]
if (!url) {
  console.error('Usage: node record-playwright.mjs <url> [totalScrollPx] [steps]')
  process.exit(1)
}

const totalScroll = parseInt(process.argv[3] ?? '4000', 10)
const steps = parseInt(process.argv[4] ?? '200', 10)

const browser = await chromium.launch()
const ctx = await browser.newContext({
  viewport: { width: 1440, height: 900 },
  recordVideo: { dir: '/tmp/', size: { width: 1440, height: 900 } },
})

const page = await ctx.newPage()
await page.goto(url)
await page.waitForTimeout(1000)

for (let i = 0; i < steps; i++) {
  await page.mouse.wheel(0, totalScroll / steps)
  await page.waitForTimeout(16)
}

await page.waitForTimeout(500)
const videoPath = await page.video().path()
await ctx.close()
await browser.close()

console.log('Video saved to:', videoPath)
