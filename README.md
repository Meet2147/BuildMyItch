# RazorpayItch — three tools for small shop owners

Three **standalone** neumorphic SaaS apps for non-technical shopkeepers. Each runs on
its own and has its own login, but they share one admin-managed access system: you
(the admin) add a shop owner's email; they set a password on first visit and can only
touch what you've granted them. The admin has every permission.

| App | Directory | Solves |
|-----|-----------|--------|
| 🏪 **MeriDukaan Online** | `voicestore/` | Speak a description → a full storefront website (Claude turns speech into a site spec). |
| 💸 **QuickPay** | `quickpay/` | One-tap payroll for teams under 10 — handles unpaid days, overtime, festival bonuses. |
| 📦 **StockSense** | `stocksense/` | Reads your sales trend and tells you what to reorder before you run out. |

Also in this repo (separate from the shop-owner suite):

| App | Directory | Solves |
|-----|-----------|--------|
| 🦴 **JawForge** | `jawforge/` | Native SwiftUI iOS app — scan your face, get an on-device jawline analysis and a daily training routine. See `jawforge/README.md`. |

Everything is deliberately **smooth and low-friction** — email-first login, one-click
actions, sensible defaults — because shopkeepers don't like fiddly software.

## Architecture

```
backend/     Shared Node + Express + SQLite API (auth, permissions, Claude proxy)
shared/      Neumorphic UI kit + auth + admin panel (imported by all 3 apps via @shared)
voicestore/  React + Vite + TS app   (port 5173)
quickpay/    React + Vite + TS app   (port 5174)
stocksense/  React + Vite + TS app   (port 5175)
```

- **Auth**: admin adds an email → owner claims it by setting a password → JWT.
- **Permissions**: per-app (`voicestore`, `quickpay`, `stocksense`) plus fine-grained
  actions (e.g. `voicestore:publish`, `quickpay:run`, `stocksense:forecast`). Admin
  bypasses all checks. Managed from the ⚙️ Admin panel inside any app.
- **AI**: the three "smart" features call the Claude API (`claude-opus-4-8`) through the
  backend, so no key ever reaches the browser.

## Setup

```bash
npm install                 # installs all workspaces

# add your Claude key so the AI features work
cp backend/.env.example backend/.env
#   → edit backend/.env and set ANTHROPIC_API_KEY=sk-ant-...
```

The super-admin is seeded from `ADMIN_EMAIL` in `backend/.env`
(default `meetjethwa3@gmail.com`). It has no password until you set one on first login.

## Run

```bash
npm run dev          # backend + all three apps together
# or individually:
npm run backend      # http://localhost:4000
npm run voicestore   # http://localhost:5173
npm run quickpay     # http://localhost:5174
npm run stocksense   # http://localhost:5175
```

## First-time flow

1. Open any app (e.g. http://localhost:5173), enter the admin email, set a password.
2. Click **⚙️ Admin** → invite a shop owner by email, tick the apps/actions they get.
3. The owner opens the app, enters their email, sets their own password, and is in —
   seeing only what you granted.

> Without a real `ANTHROPIC_API_KEY`, the app runs fine but the AI features
> (voice→site, payroll notes, forecasts) return a friendly "add your key" message.
> `GET /api/health` reports `claudeReady`.
