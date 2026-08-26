# 🌅 Aubade

An alarm clock that treats waking up as something worth designing.
**iPhone only** — see [`CONCEPT.md`](CONCEPT.md) §6 for why that's a feature.

> **Status: early, and honest about one thing.** `AubadeCore` is written and
> tested. The app is written but **has not been compiled** — there's no Swift
> toolchain in the environment it was built in. And the alarm currently rings
> through **notifications, not AlarmKit**, which means it will not break through
> the silent switch. That limitation is stated inside the app, not buried here.

---

## Run the tests

```bash
cd apple/aubade
swift test
```

Covers the parts that have to be right: when to ring inside a wake window,
how the volume ramp is shaped, what the snooze ladder costs, and the alarm
arithmetic that decides "next Monday at 6:40".

## Build the app

```bash
brew install xcodegen
cd apple/aubade
xcodegen generate
open Aubade.xcodeproj
```

---

## The seam that matters

Everything platform-specific about being an alarm clock sits behind one
protocol, `AlarmScheduling`:

| Implementation | Rings through a Focus | Rings through silent | Status |
|---|---|---|---|
| `NotificationScheduler` | yes (time-sensitive) | **no** | working today |
| `AlarmKitScheduler` | yes | yes | **stub — write this next** |

`AlarmKitScheduler.swift` is deliberately a stub with a numbered to-do list
rather than plausible-looking API calls. It was written without an SDK to check
against, and inventing the API would have produced a project that doesn't
build. Everything around it is real; that one file is the piece to write with
the documentation open, and it should be proven on a device before anything
else in the app gets polished.

Each scheduler carries its own `capabilityNote`, and the alarms screen prints
it verbatim under **"Before you rely on it"**. When AlarmKit lands, that
sentence changes on its own. An alarm app that overstates what it can do is
worse than one that admits its limits.

## What's built

**`AubadeCore`** — no Apple frameworks beyond Foundation, so it tests in a second.

- `AlarmSchedule` — "by 6:40" plus a window, and the arithmetic for the next
  occurrence. Occurrences are materialised locally, a fortnight at a time, so
  firing never depends on a network.
- `WakeWindow` — picks the moment inside the window from motion samples.
  Strongest upswing wins, ties go later (sleep is worth keeping), and it will
  **never** return a time after the hard time. With no usable signal it returns
  the hard time and reports `usedSignal: false` — the app never claims to have
  detected something it didn't.
- `RampCurve` — shallow for most of the ramp, steep at the end. Opens at 15%,
  voices enter one at a time so the rise adds information rather than just
  volume.
- `SnoozeLadder` — 12, 8, then 5 minutes, each restart opening louder. Stops
  offering after four: at that point the alarm has failed and the answer is a
  different alarm, not another five minutes.
- `SoundPalette` — six palettes as synthesis parameters, not audio files.

**The app** — the alarms list, a carved time dial with five-minute detents, the
editor (window, days, sound), the ringing screen with the sunrise gradient and
hold-to-breathe dismissal, and the night face.

## What isn't built

1. **Compile it.** Nothing here has been through a compiler.
2. **AlarmKit.** The whole reason the app can exist. See above.
3. **The sound engine.** `SoundPalette` describes six palettes; nothing
   synthesises them yet. `RampCurve` is ready for whatever does.
4. **Motion sensing.** `WakeWindow` takes samples and nothing produces them, so
   every alarm currently rings at its hard time — correctly, and it says so.
5. **Screen-brightness ramp.** The gradient animates; `UIScreen.brightness`
   isn't driven yet.
6. **Wind-down, StandBy, HomeKit.** After the core is good.
7. **CloudKit restore.** Model is shaped for it; entitlements aren't set.

## Notes

- There is no `ringPolicy` and no `modifiedBy` field. One device, one writer,
  nothing to arbitrate. Both come back the day there's a Watch app — the design
  is kept in [`../architecture/SYNC.md`](../architecture/SYNC.md) §5 rather than
  deleted.
- `WakeEvent` sleep history is deliberately absent from the model. It's the most
  sensitive data the app would hold and no feature needs it to be portable.
- The design system is duplicated from Sill rather than shared. Extracting a
  common `SoftStoneKit` is worth doing once both apps stop moving; doing it now
  would couple two things still changing shape.
