# JawForge marketing assets

- `appstore/iphone-6.9/` — six App Store screenshots at 1320×2868 (iPhone 6.9" portrait, framed marketing style)
- `appstore/ipad-13/` — six App Store screenshots at 2064×2752 (iPad Pro 13" portrait, full-screen UI)
- `device-frames/` — raw phone-framed captures of each screen
- `tools/` — the HTML preview (a 1:1 web mirror of the app) and the
  Playwright scripts that generate everything:
  `npm i playwright-core`, then `node shoot.mjs` (device frames),
  `node gen-store.mjs` (iPhone marketing shots), `node shoot-ipad.mjs`
  (iPad full-screen shots). Scripts expect the Playwright Chromium at
  /opt/pw-browsers/chromium — point `executablePath` at any local Chromium.

These are generated from the web preview, which mirrors the SwiftUI app's
UI and logic. For final App Store submission you can also re-capture from
the Xcode Simulator (⌘S) if App Review asks for native captures.
