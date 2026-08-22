import { chromium } from 'playwright-core';
import path from 'path'; import fs from 'fs';
const dir = path.dirname(new URL(import.meta.url).pathname);
const out = path.join(dir, 'icons'); fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const page = await browser.newPage({ viewport: { width: 1100, height: 3200 }, deviceScaleFactor: 1 });
await page.goto('file://' + path.join(dir, 'icon.html'));
await page.waitForTimeout(400);
for (const id of ['a', 'b', 'c']) {
  await page.locator('#' + id).screenshot({ path: path.join(out, id + '.png') });
  console.log('captured', id);
}
await browser.close();
