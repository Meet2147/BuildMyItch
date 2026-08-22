import { chromium } from 'playwright-core';
import path from 'path';
import fs from 'fs';

const dir = path.dirname(new URL(import.meta.url).pathname);
const out = path.join(dir, 'shots');
fs.mkdirSync(out, { recursive: true });

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const page = await browser.newPage({ viewport: { width: 520, height: 1000 }, deviceScaleFactor: 2 });
await page.goto('file://' + path.join(dir, 'jawforge-preview.html'));
await page.waitForTimeout(1200); // fonts + first paint

const phone = page.locator('#phone');
async function shot(name) {
  await page.waitForTimeout(450);
  await phone.screenshot({ path: path.join(out, name + '.png') });
  console.log('captured', name);
}

// 1-2. Onboarding: welcome + lifestyle quiz page
await page.evaluate(() => tour('onboarding'));
await shot('1-onboarding-welcome');
await page.evaluate(() => { obPage = 2; render(); });
await shot('2-onboarding-lifestyle');
await page.evaluate(() => { obPage = 3; render(); });
await shot('3-onboarding-training');

// 4. Paywall
await page.evaluate(() => tour('paywall'));
await shot('4-paywall');

// 5. Scan (live camera guide with sweep animation mid-frame)
await page.evaluate(() => tour('scan'));
await page.waitForTimeout(900);
await shot('5-scan');

// 6. Analyzing overlay mid-stage
await page.evaluate(() => { isPro = true; capture(); });
await page.waitForTimeout(1300);
await phone.screenshot({ path: path.join(out, '6-analyzing.png') });
console.log('captured 6-analyzing');
await page.waitForTimeout(1500); // let it finish into results

// 7. Results (fix metrics for a nice, representative frame)
await page.evaluate(() => {
  pendingMetrics = { gonialAngle: 131, widthRatio: 0.78, lowerFace: 0.52, symmetry: 0.87 };
  pushed = { kind: 'results', m: pendingMetrics, saved: false };
  render();
});
await page.waitForTimeout(1400); // ring animation
await shot('7-results');

// 8. Train (with a profile-tuned routine and a completed exercise)
await page.evaluate(() => {
  profile = { age: '18–29', height: 175, weight: 72, sleep: 'Left side', chew: 'Mostly right',
              mouth: 'Sometimes', screen: '8+ h', freq: '3–4× a week', mins: 10, goal: 'Sharper jaw angle', remind: true };
  const k = dateKey();
  completions[k] = ['mewing', 'chin_tucks'];
  tour('train');
});
await shot('8-train');

// 9. Exercise detail with timer
await page.evaluate(() => push({ kind: 'exercise', id: 'jaw_resistance' }));
await shot('9-exercise');

// 10. Progress with seeded history + free-tier lock
await page.evaluate(() => {
  const day = 864e5, now = Date.now();
  scans = [
    { date: now - 28 * day, m: { gonialAngle: 136, widthRatio: 0.78, lowerFace: 0.57, symmetry: 0.84 } },
    { date: now - 21 * day, m: { gonialAngle: 133, widthRatio: 0.80, lowerFace: 0.55, symmetry: 0.86 } },
    { date: now - 14 * day, m: { gonialAngle: 130, widthRatio: 0.82, lowerFace: 0.54, symmetry: 0.87 } },
    { date: now - 7 * day,  m: { gonialAngle: 127, widthRatio: 0.84, lowerFace: 0.53, symmetry: 0.88 } },
    { date: now - 1 * day,  m: { gonialAngle: 124, widthRatio: 0.86, lowerFace: 0.52, symmetry: 0.90 } },
  ].map(s => ({ ...s, score: scores(s.m).overall }));
  isPro = false;
  tour('progress');
});
await shot('10-progress');

await browser.close();
console.log('done');
