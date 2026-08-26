# Soft Stone — two Apple-native apps

Two small, opinionated apps for iPhone, iPad and Mac that share one design
language, one sync spine, and one point of view about time.

| App | Directory | One line |
|-----|-----------|----------|
| 🪨 **Cairn** | `cairn/` | A todo app that plans your day for you, then gets out of the way. |
| 🌅 **Aubade** | `aubade/` | An alarm clock that treats waking up as something worth designing. |

They ship separately, install separately, and are useful alone. If you have
both, they know about each other: Aubade knows when your first hard task is,
Cairn knows when you actually got up.

```
apple/
  design-system/   Soft Stone — the shared visual + motion language
  architecture/    Keystone — the shared CloudKit sync spine
  cairn/           Todo app concept
  aubade/          Alarm app concept
```

---

## Why these two

Both categories are crowded and both are badly served at the premium end.

**Todo apps** fail in one of two directions. Either they're a database with a
UI on top (Notion, ClickUp, most of Todoist) and you spend your energy on the
system instead of the work — or they're so thin (Reminders) that they can't
hold a real week. The gap is an app that is *small to operate* but *smart about
scheduling*. You dump things in; it decides what today looks like.

**Alarm apps** were dead for a decade because iOS wouldn't let a third-party app
ring through silent mode or a Focus. With AlarmKit that changed — a third-party
alarm can now actually be an alarm. Almost nothing has been built on it that
looks good. Sleep Cycle is ugly, Alarmy is hostile by design. Nobody has made
the *beautiful* one.

## The bar: it must not look vibe-coded

That phrase means something specific and it's worth writing down, because it's
the acceptance criteria for every screen we design.

Vibe-coded apps share a tell: **every element got the same amount of attention.**
Uniform 16pt padding, uniform corner radius, uniform shadow on everything,
one weight of type, emoji instead of icons, a settings screen that's an
undifferentiated stack of toggles. It reads as *generated* because there's no
evidence of anyone deciding what matters.

Apps that feel hand-made show their priorities:

1. **Hierarchy is visible.** On any screen you can name the one thing it's for
   within half a second. Everything else is quieter — smaller, lower contrast,
   further from the optical center.
2. **The empty state is designed.** So is the error state, the first-run state,
   the "you have 200 tasks" state, and the "it's 3am" state.
3. **Motion is causal.** Things move because you moved them. A sheet grows from
   the button you tapped, not from the bottom of the screen by default.
4. **Text is written.** "No tasks today" is a placeholder. "Nothing due — go
   outside" is a decision. Every string in both apps gets written by a person.
5. **It's fast at the boring moments.** Launch to interactive under 400ms, list
   scrolling that never drops a frame on a 120Hz display, a keyboard that comes
   up already focused. Speed is the most under-rated aesthetic property.
6. **It respects the platform.** Real toolbars on Mac, real keyboard shortcuts,
   real drag-and-drop between apps, real Dynamic Type support up to AX5. A
   universal SwiftUI blob that's identical on all three devices is its own kind
   of vibe-coding.
7. **The details nobody asked for.** Haptics tuned per gesture. Numerals that
   don't jitter because we used monospaced digits. A share sheet that produces
   a nice-looking image, not a URL.

## Design language, in one paragraph

Soft Stone is neumorphism that survived contact with accessibility review.
Surfaces are extruded from a single warm-grey ground, lit consistently from the
top-left, with two shadows — a light one and a dark one — defining every edge.
But **relief carries structure, not meaning**: text, icons and state always
carry their own contrast, so the app is fully usable if you strip every shadow
away (and it does strip them, automatically, under Increase Contrast and
Reduce Transparency). Colour is used almost nowhere. Each app gets exactly one
accent — Cairn a slate blue, Aubade a low amber — and spends it carefully.

Full spec: [`design-system/SOFT-STONE.md`](design-system/SOFT-STONE.md).

## Sync, in one paragraph

One CloudKit private database per app, SwiftData for the local store, CloudKit
mirroring for transport. No accounts, no server, no subscription infrastructure
to run — you sign in with the Apple Account you already have. The interesting
problem isn't moving records, it's **arbitration**: which of your four devices
actually rings at 6:40am, and what happens to the other three when you dismiss
it. That's the part worth engineering.

Full spec: [`architecture/SYNC.md`](architecture/SYNC.md).

## Stack

| Layer | Choice | Why |
|-------|--------|-----|
| UI | SwiftUI, one codebase, three tuned layouts | Fastest path to a consistent design system across all three platforms |
| Local store | SwiftData | Native, observable, integrates with CloudKit mirroring for free |
| Sync | CloudKit private DB | Free at our scale, no backend to run, user already has an account |
| Alarms | AlarmKit (iOS/iPadOS), helper + notifications (Mac) | Only way to ring through silent mode and Focus |
| Intelligence | Foundation Models (on-device) | Natural-language capture with zero cost, zero latency, zero privacy story to write |
| Surfaces | WidgetKit, App Intents, Live Activities, Control Center | Where the apps actually live day to day |

> API-availability note: AlarmKit and the on-device Foundation Models framework
> are both recent (iOS 26 era). Everything here should be checked against the
> current SDK before it becomes a plan — capabilities, entitlements and review
> requirements in these two areas move fast.

## Business shape

Both apps: paid up front, no subscription, no accounts, no telemetry.
Roughly $12 for Cairn, $8 for Aubade, a bundle at $16. There is no server cost
to amortise, so a subscription would be rent-seeking and users can smell it.
A one-time price is also the strongest possible signal that the app is finished
and won't grow a "Pro" upsell inside itself.

---

Concept docs: [Cairn](cairn/CONCEPT.md) · [Aubade](aubade/CONCEPT.md)
