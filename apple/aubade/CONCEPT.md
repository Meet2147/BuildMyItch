# 🌅 Aubade

> *aubade* (n.) — a poem or piece of music appropriate to the dawn.

**An alarm clock that treats waking up as something worth designing.**

---

## 1. The thesis

The iPhone alarm is the most-used app on the device and one of the least
considered. It is a 2007 interface that jolts you out of your deepest sleep with
a sound engineered to be unignorable, and its only affordance for the fact that
this is unpleasant is a 9-minute snooze.

Third parties couldn't fix it, because until AlarmKit an app that wasn't Clock
couldn't ring through silent mode or a Focus. So the category filled with apps
that solve the wrong problem: Alarmy makes you photograph a sink, Sleep Cycle
buries a good idea under an ad-supported dashboard. **Nobody made the beautiful
one**, because for a decade you couldn't.

Aubade is the beautiful one. It does three things:

1. **Wakes you at the right moment**, not at the exact minute you typed.
2. **Wakes you gradually**, with light and sound that start below your waking
   threshold and rise over minutes.
3. **Ends the night before.** The wake experience is mostly determined by the
   wind-down, so the app owns both ends.

## 2. The core mechanic: the wake window

You don't set 6:40. You set **"by 6:40"**, and a window — 10, 20 or 30 minutes.
Aubade rings at the best moment inside `[6:10, 6:40]` and guarantees it never
rings later than 6:40.

"Best moment" is decided by whatever signal is available, degrading gracefully:

| Signal available | How the moment is chosen |
|------------------|--------------------------|
| Apple Watch worn | Heart rate + motion → wake on a light-sleep upswing |
| iPhone on the mattress | Accelerometer movement clustering |
| Nothing (phone on a desk) | Ring at the hard time; the window silently does nothing |

That last row is important and most competitors hide it. If we can't detect
anything, **we say so**, once, in the setup flow — and the app still works,
it just becomes a very pretty ordinary alarm. Pretending to detect sleep from a
phone across the room is the kind of lie that makes an app feel cheap.

## 3. The wake ritual

### Sound

The dominant design decision. Alarms are jarring because they start at full
volume with a hard attack. Aubade's tones are **generative and rising**:

- Start at ~15% volume, 3–5 minutes before the target, with a low sustained
  tone that sits under the waking threshold.
- Layers enter one at a time — a second voice, then a slow rhythmic element —
  each entry a small increase in information, not volume.
- Volume ramps on a curve that's shallow for the first 60% and steep at the end,
  so there's a real guarantee you'll wake, but the first 3 minutes are gentle.
- Six palettes, each generated rather than looped so there's no seam and no
  point where you recognise "the bit before it gets loud": **Glass, Ember,
  Rainfall, Bell Garden, Low Strings, Tide.**
- Composed with actual synthesis (AVAudioEngine), so a 5-minute wake is 40KB of
  parameters, not a 5-minute audio file.

### Light

Full-screen sunrise gradient starting at the same time as the first tone.
Screen brightness ramps from ~2% to ~85% over the ramp period. On iPad — often
the bedside device — this is genuinely effective as a wake light. The gradient
uses the same amber as the app's accent and moves with `Motion.drift`, slow
enough that you can't see it move but it's never the same twice.

### Dismissal

Not a math problem. Not a barcode. **Hold and breathe:**

A soft carved ring on screen. Press and hold; the ring fills over ~8 seconds
while a slow haptic pulse paces an inhale-hold-exhale. Release early and it
drains. You cannot do this in your sleep — it takes sustained attention — but
it's calm rather than punitive, and it leaves you slightly more awake in a way
that shouting at a QR code does not.

Snooze exists, is one large easy tap, and is **not** 9 minutes: it's adaptive.
First snooze 12 min, second 8, third 5, and the sound restarts at a higher floor
each time. Rewarding the snooze less each time is more honest than removing it.

### The first 30 seconds after

The screen you see when you dismiss is the one design opportunity nobody uses.
Aubade shows a single quiet card: the time, the weather line, and — if Cairn is
installed — **the first real thing on today**. One sentence. Then it gets out of
the way. No dashboard, no sleep score, no graph of your night.

## 4. The other half: wind-down

An alarm app that only exists at 6am has no way to help you.

- **Set a bedtime, get a wind-down.** At `bedtime − 45m` the app offers a
  single card: dim the room (HomeKit scene if you have one), a wind-down sound,
  and the tomorrow-morning preview so your brain stops rehearsing it.
- **Night face.** After bedtime the whole app switches to a deep, near-black
  variant of Soft Stone with amber-only ink — usable at 3am without destroying
  your night vision, and the relief becomes very subtle because at low
  brightness heavy shadows just read as smudges.
- **A clock worth looking at.** In night mode Aubade is a genuinely beautiful
  bedside clock: giant monospaced-digit time on the carved ground, amber, dimmed
  to near-invisibility, tap anywhere to brighten for 5 seconds. This is the
  feature that gets it screenshotted.

## 5. Screens

| Screen | Contents |
|--------|----------|
| **Alarms** | 2–4 lifted cards. Each is time (large, monospaced), repeat days as small caps, sound palette, and a real physical-feeling toggle that carves in when off. Not a table view. |
| **Editor** | A carved circular dial for time — drag with 5-minute haptic detents, or tap the numerals to type. Below: window size, days, palette (with instant preview), ring policy. |
| **Night face** | The bedside clock. Also the app's screensaver-equivalent on Mac and StandBy mode on iPhone. |
| **Ringing** | Full-bleed sunrise gradient, time, the breathe ring, snooze. Nothing else on screen at all. |
| **Wind-down** | One card, appears on schedule, dismissible forever with one tap. |
| **Settings** | Grouped, written, with real explanatory text — not a stack of toggles. Includes the honest "what can this device detect?" panel. |

## 6. The hard part: cross-device arbitration

Four devices, one alarm. This is the real engineering in the app and it's what
separates it from a weekend project.

The **schedule** syncs. The **firing** is local — each device materialises its
own OS-level alarm from the synced schedule. So without arbitration, an alarm
set on your Mac rings on your iPhone, iPad, Mac and Watch simultaneously at
6:40am, and dismissing one leaves three going. That is a one-star review.

Each alarm carries a **ring policy**:

- **Bedside** (default) — rings on the device you designate per-location. Aubade
  learns this: the device that has been stationary, charging, and face-down/idle
  through the night is the bedside device. Others stay silent.
- **All devices** — for people who need it. Dismissal propagates.
- **This device only** — for a nap timer or a Mac-side reminder.

**Dismissal propagation** can't rely on CloudKit push latency (seconds to
minutes, not guaranteed). Layered approach:
1. Local network — a small Bonjour/Network.framework beacon between your own
   devices on the same Wi-Fi, which is the case for ~all bedside scenarios.
   Sub-second, works with no internet.
2. CloudKit silent push as the durable fallback.
3. **A device that has been ringing for >90s with no local ack from a device
   that dismissed it stops itself anyway.** Fail quiet, not fail loud — the
   failure mode of an alarm app must never be "it wouldn't stop".

The inverse failure — it doesn't ring at all — is handled by never depending on
sync for firing. Each device schedules its own alarm from local data. If sync is
broken for a week, every device still rings on last-known schedule.

## 7. Platform reality check

| Platform | How alarms actually fire |
|----------|--------------------------|
| **iPhone / iPad** | AlarmKit. Rings through silent mode and Focus, presents the system alert UI and a Lock Screen / Dynamic Island Live Activity, supports a custom sound and a secondary button that opens the app for our full ringing screen. Requires explicit user authorization. |
| **Apple Watch** | Haptic wake is the best wake there is. Also the best sleep-stage signal. Check current SDK for AlarmKit availability on watchOS; fall back to a paired-device haptic notification if unavailable. |
| **Mac** | No AlarmKit. Alarms fire via a `SMAppService` login-item helper that stays resident, plays audio through a dedicated `AVAudioEngine` session, wakes the display, and brings the app forward. Reliable while the Mac is awake; if it's asleep, an `IOPMScheduleUserWakeRequest`-style wake schedule is needed — verify what's still permitted, and **be honest in the UI** about Mac reliability rather than promising something the OS won't guarantee. |

> Treat this whole table as needing verification against the current SDK before
> committing. AlarmKit's entitlements, review requirements and platform coverage
> are the single biggest external risk to the project, and a "we'll figure the
> Mac out later" attitude here is exactly how a beautiful alarm app ends up
> with a one-star average.

## 8. Data model (sketch)

```swift
@Model final class Alarm {
    var id: UUID
    var label: String?
    var hardTime: DateComponents     // "by 6:40"
    var window: Int                  // 0/10/20/30 minutes before hardTime
    var days: Weekdays               // OptionSet; empty == one-shot
    var palette: SoundPalette
    var rampMinutes: Int             // default 5
    var lightWake: Bool
    var ringPolicy: RingPolicy       // .bedside / .allDevices / .thisDevice(deviceID)
    var isEnabled: Bool
    var modifiedAt: Date
    var modifiedBy: String           // device ID — needed for conflict resolution
}

@Model final class WakeEvent {       // local, not synced
    var alarmID: UUID
    var firedAt: Date
    var dismissedAt: Date?
    var snoozeCount: Int
    var chosenOffset: Int            // how far inside the window we rang
}
```

`WakeEvent` stays on-device deliberately. Sleep timing is the most sensitive
data either app touches, and there is no feature that justifies syncing it.

## 9. Deliberately not doing

- ❌ A sleep score, a dashboard, or graphs of your night. It's an alarm clock.
- ❌ Snore recording / audio capture while you sleep. The privacy cost is real
  and the feature is a novelty.
- ❌ Ads, subscriptions, or a "premium sounds" pack.
- ❌ Punitive dismissal (photograph the sink, solve equations, shake 50 times).
- ❌ Guided meditations or a content library.
- ❌ Health claims of any kind. We say "light sleep", never "REM", and we never
  imply a medical benefit.

## 10. Build order

1. Local alarms on iOS with AlarmKit, one sound, plain UI. Prove the hard part first — if AlarmKit doesn't do what we need, we want to know in week one, not month three.
2. Sound engine: generative palettes, ramp curve.
3. Ringing screen, breathe-to-dismiss, sunrise gradient, night face.
4. Soft Stone applied; night variant.
5. CloudKit schedule sync + ring arbitration (the local-network beacon).
6. Watch app: haptic wake + sleep signal.
7. Wind-down, StandBy, HomeKit scene hook.
8. Mac helper — last, because it's the least certain.
