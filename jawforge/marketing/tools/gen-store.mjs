import { chromium } from 'playwright-core';
import path from 'path';
import fs from 'fs';

const dir = path.dirname(new URL(import.meta.url).pathname);
const shots = path.join(dir, 'shots');
const out = path.join(dir, 'appstore');
fs.mkdirSync(path.join(out, 'iphone-6.9'), { recursive: true });
fs.mkdirSync(path.join(out, 'ipad-13'), { recursive: true });

const img = name => 'data:image/png;base64,' +
  fs.readFileSync(path.join(shots, name + '.png')).toString('base64');

const page_ = html => `
<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@800;900&display=swap">
<style>
  *{margin:0;box-sizing:border-box}
  body{width:100vw;height:100vh;overflow:hidden;position:relative;
    background:
      radial-gradient(90rem 60rem at 15% -10%, rgba(23,160,191,.14), transparent 60%),
      radial-gradient(80rem 60rem at 110% 115%, rgba(115,93,219,.16), transparent 60%),
      #e3e8f2;
    font-family:Nunito,-apple-system,sans-serif;color:#293047;
    display:flex;flex-direction:column;align-items:center}
  .eyebrow{display:flex;align-items:center;gap:.45em;font-weight:900;letter-spacing:.02em}
  .eyebrow .dot{color:#17a0bf}
  h1{font-weight:900;text-align:center;letter-spacing:-.02em;line-height:1.06;text-wrap:balance}
  .sub{font-weight:800;color:#6d768e;text-align:center}
  .phones{display:flex;justify-content:center;align-items:flex-start}
  .phones img{display:block;filter:drop-shadow(0 60px 90px rgba(41,48,71,.35))}
</style></head><body>${html}</body></html>`;

const iphoneShot = (image, headline, sub) => page_(`
  <div style="padding-top:150px" class="eyebrow" ><span style="font-size:54px"><span class="dot">Jaw</span>Forge</span></div>
  <h1 style="font-size:132px;margin:44px 90px 26px">${headline}</h1>
  <div class="sub" style="font-size:52px;margin:0 120px 90px">${sub}</div>
  <div class="phones"><img src="${image}" style="width:1120px"></div>`);

const ipadShot = (imgA, imgB, headline, sub) => page_(`
  <div style="padding-top:150px" class="eyebrow"><span style="font-size:60px"><span class="dot">Jaw</span>Forge</span></div>
  <h1 style="font-size:128px;margin:40px 140px 24px">${headline}</h1>
  <div class="sub" style="font-size:50px;margin:0 160px 100px">${sub}</div>
  <div class="phones" style="gap:70px">
    <img src="${imgA}" style="width:830px;margin-top:60px">
    <img src="${imgB}" style="width:830px">
  </div>`);

const IPHONE = [
  ['1-scan',       iphoneShot(img('5-scan'), 'Scan your face.<br>Know your score.', 'On-device analysis with Apple Vision — photos never leave your phone')],
  ['2-results',    iphoneShot(img('7-results'), 'Four metrics.<br>Zero guesswork.', 'Jaw angle, width, proportion and symmetry — scored and explained')],
  ['3-plan',       iphoneShot(img('8-train'), 'A plan built<br>for your face.', 'Your routine adapts to your scan, your habits and your goal')],
  ['4-onboarding', iphoneShot(img('2-onboarding-lifestyle'), 'Five questions.<br>Fully personal.', 'Sleep, chewing, posture and time budget all shape your program')],
  ['5-progress',   iphoneShot(img('10-progress'), 'Watch the<br>number go up.', 'Every scan charts your trend — re-scan weekly and see it move')],
  ['6-pro',        iphoneShot(img('4-paywall'), 'Go Pro.<br>Get sharp.', 'Unlimited scans, full history and an adaptive routine')],
];

const IPAD = [
  ['1-scan-results', ipadShot(img('5-scan'), img('7-results'), 'Scan your face. Know your score.', 'On-device analysis with Apple Vision — photos never leave your device')],
  ['2-plan-exercise', ipadShot(img('8-train'), img('9-exercise'), 'A plan built for your face.', 'Guided exercises with timers, streaks and TMJ-safe form cues')],
  ['3-progress-pro', ipadShot(img('10-progress'), img('4-paywall'), 'Watch the number go up.', 'Track your trend — go Pro for unlimited scans and full history')],
];

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });

async function render(list, w, h, sub) {
  const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
  for (const [name, html] of list) {
    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(out, sub, name + '.png') });
    console.log(sub, name, `${w}x${h}`);
  }
  await page.close();
}

await render(IPHONE, 1320, 2868, 'iphone-6.9');   // iPhone 6.9" portrait
await render(IPAD, 2064, 2752, 'ipad-13');        // iPad Pro 13" portrait
await browser.close();
console.log('done');
