# 🪨 Sill

A todo app that plans your day for you, then gets out of the way.
iPhone, iPad and Mac. Concept and reasoning: [`CONCEPT.md`](CONCEPT.md).

> **Status: early.** The logic is written and covered by tests; the app layer is
> written but has **not been compiled** — it was built in a Linux container with
> no Swift toolchain and no Xcode (the environment's network policy blocks
> `download.swift.org`). Expect to fix compile errors on the first build. The
> package tests are the part you can trust today, and they're the part that
> matters most.

---

## Layout

```
Package.swift          SillCore — all the logic, no Apple frameworks but Foundation
Sources/SillCore/
  TaskType.swift       deep / admin / errand / social / idle
  Band.swift           a day is four bands, not 24 hours
  Recurrence.swift     after-completion by default, fixed weekday on request
  Capture/             one line of typing → real tasks
  Plan/                fitting a day, and the two things Sill learns
Tests/SillCoreTests/   the corpus, and the promises the planner makes

project.yml            XcodeGen spec for the app
App/Sill/
  App/                 entry point, three-platform root
  Model/               SwiftData store — one flat entity, no relationships
  Design/              Soft Stone: tokens, elevation, motion, type
  Features/            Today, capture, the pile
```

The split is the point. Everything likely to be *wrong* — date parsing, task
splitting, capacity arithmetic — is in a plain library with no UI and no
frameworks, so it runs in a second on any machine. Everything likely to be
*ugly* is in the app, where you have to look at it anyway.

## Run the tests

No Xcode project needed, no simulator, no signing:

```bash
cd apple/sill
swift test
```

That exercises the capture parser against its corpus, the day planner against
every promise it makes, recurrence, and calibration.

## Build the app

```bash
brew install xcodegen
cd apple/sill
xcodegen generate
open Sill.xcodeproj
```

The `.xcodeproj` is generated, not checked in — a merge conflict should never be
inside a `.pbxproj`. Set `DEVELOPMENT_TEAM` in `project.yml` (or sign locally in
Xcode) and it runs on iOS and macOS from the same target.

CloudKit is not switched on yet. The model is already shaped for it — every
property optional or defaulted, no unique constraints, no relationships — so
turning it on is entitlements plus a container, not a rewrite. See
[`../architecture/SYNC.md`](../architecture/SYNC.md).

---

## What's built

**Capture** — one line in, one or more tasks out, on-device and deterministic.

| It handles | Example |
|------------|---------|
| Brain dumps | `pick up parcel, gym, book flights, reply to Sam` → four tasks |
| Relative days | `tomorrow morning`, `next week`, `in 3 days`, `saturday` |
| Named dates | `june 3`, `3rd sep` |
| Deadlines | `by friday` — and `before the Thursday review`, which backdates to Wednesday |
| Times | `at 7am`, `19:00`, `at 7` — a bare hour takes whichever reading comes soonest |
| Durations | `30m`, `2h`, `1.5h`, `half an hour`, `quick` |
| Recurrence | `every 5 days` (after completion), `every tuesday` (genuinely fixed), `daily` |
| Type | from the verb, with light stemming — `meetings`, `shopping`, `stretching` |
| Shared context | `tomorrow: gym, laundry` applies the date to both |

Two rules it never breaks: it never splits on the word *and* (`salt and pepper`
is one thing, and there's no cheap way to tell that from `gym and laundry`), and
it never returns nothing — if it can't parse your sentence, it keeps your
sentence.

**Planning** — a day you can actually finish. Ninety free minutes gets ninety
minutes of work. At most two deep tasks a day. Errands never eat a band's
budget. Idle work is never scheduled. A pin always wins. Anything genuinely due
today is placed even on a full day, because a missed hard deadline is the one
failure the app is responsible for.

**Learning** — exactly two things, both from data the app already has, neither
ever shown to the user: when you actually finish deep work, and how badly you
over-commit. The over-commit factor eases in over ten days and is clamped, so
one chaotic week can't halve every future day. Nothing else is learned — what
matters and what you should work on aren't an app's business.

**The app** — Today (bands, rows, the done well, a written empty state), the
capture field with live parse chips, and the Pile with the thirty-day
*still real?* card. Soft Stone throughout, with the Increase Contrast, Reduce
Motion and Dynamic Type paths written rather than assumed.

## What isn't built yet

Honest list, roughly in the order it should happen:

1. **Compile it.** See the status note. Nothing here has been through a compiler.
2. **Calendar awareness.** `DayContext.nominal` invents the free minutes; it
   should come from EventKit. Until then the plan is shaped right but the
   capacity is a guess.
3. **Calibration wiring.** `EstimateCalibrator` is written and tested but
   nothing feeds it `DayOutcome`s yet — `TodayModel.calibration` is still
   `.unknown`.
4. **Someday.** Every undated task is currently a candidate for today. That's
   correct for a working list, but there's no way yet to say "one day, not
   now" other than dating it far out.
5. **Swipe to complete.** Rows complete on tap and via the context menu. The
   swipe in the concept doc needs a custom gesture, since a `List` background
   fights Soft Stone.
6. **Drag between bands.** `TodoStore.move(_:to:on:)` exists; nothing calls it.
7. **CloudKit.** Entitlements and container.
8. **Review, widgets, App Intents, the Mac menu-bar panel.** ⌘N focuses the
   capture field today; the global-hotkey menu-bar extra is still to come.
   All deliberately after the core is good — see `CONCEPT.md` §7.

## Notes for whoever picks this up

- The model is called `Todo`, not `Task`, so it doesn't shadow Swift
  concurrency's `Task` inside the module. Worth keeping.
- There is no `priority` field and there never should be. Priority flags fail
  because everything becomes P1; `TaskType` is the replacement and it's the
  load-bearing idea in the whole app.
- Recurrence is *after completion* by default. Fixed-interval recurrence is the
  single biggest source of overdue-guilt in every other todo app.
- The day plan is derived, never stored. That's what makes it impossible for
  two devices to disagree about it.
- Letting go is a soft delete. Silent data loss is the one outcome a personal
  list can't survive.
