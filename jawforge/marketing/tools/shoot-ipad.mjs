import { chromium } from 'playwright-core';
import path from 'path';
import fs from 'fs';

const dir = path.dirname(new URL(import.meta.url).pathname);
const out = path.join(dir, 'appstore', 'ipad-13');
fs.mkdirSync(out, { recursive: true });
// Remove the old composite shots so only true-UI screenshots remain.
for (const f of fs.readdirSync(out)) fs.unlinkSync(path.join(out, f));

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
// iPad Pro 13" portrait: 1032x1376 pt at @2x = 2064x2752 px
const page = await browser.newPage({ viewport: { width: 1032, height: 1376 }, deviceScaleFactor: 2 });
await page.goto('file://' + path.join(dir, 'ipad-preview.html'));
await page.waitForTimeout(1200);

async function shot(name) {
  await page.waitForTimeout(450);
  await page.screenshot({ path: path.join(out, name + '.png') });
  console.log('captured', name);
}

// Seed a profile + history so every screen shows real content.
await page.evaluate(() => {
  profile = { age: '18–29', height: 175, weight: 72, sleep: 'Left side', chew: 'Mostly right',
              mouth: 'Sometimes', screen: '8+ h', freq: '3–4× a week', mins: 10, goal: 'Sharper jaw angle', remind: true };
  const k = dateKey();
  completions[k] = ['mewing', 'chin_tucks'];
  const day = 864e5, now = Date.now();
  scans = [
    { date: now - 28 * day, m: { gonialAngle: 136, widthRatio: 0.78, lowerFace: 0.57, symmetry: 0.84 } },
    { date: now - 21 * day, m: { gonialAngle: 133, widthRatio: 0.80, lowerFace: 0.55, symmetry: 0.86 } },
    { date: now - 14 * day, m: { gonialAngle: 130, widthRatio: 0.82, lowerFace: 0.54, symmetry: 0.87 } },
    { date: now - 7 * day,  m: { gonialAngle: 127, widthRatio: 0.84, lowerFace: 0.53, symmetry: 0.88 } },
    { date: now - 1 * day,  m: { gonialAngle: 124, widthRatio: 0.86, lowerFace: 0.52, symmetry: 0.90 } },
  ].map(s => ({ ...s, score: scores(s.m).overall }));
  isPro = false;
});

await page.evaluate(() => tour('scan'));
await page.waitForTimeout(800);
await shot('1-scan');

await page.evaluate(() => {
  pendingMetrics = { gonialAngle: 131, widthRatio: 0.78, lowerFace: 0.52, symmetry: 0.87 };
  pushed = { kind: 'results', m: pendingMetrics, saved: false };
  render();
});
await page.waitForTimeout(1300);
await shot('2-results');

await page.evaluate(() => tour('train'));
await shot('3-train');

await page.evaluate(() => push({ kind: 'exercise', id: 'jaw_resistance' }));
await shot('4-exercise');

await page.evaluate(() => tour('progress'));
await shot('5-progress');

await page.evaluate(() => tour('paywall'));
await shot('6-pro');

await browser.close();
console.log('done');
