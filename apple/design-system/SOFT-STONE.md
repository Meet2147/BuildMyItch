# Soft Stone

The shared design language for Cairn and Aubade.

Neumorphism has a bad reputation and it earned it. The 2020 wave of it was
unusable: soft-on-soft buttons with 2:1 contrast, no visible focus state, and
no way to tell a pressed control from an unpressed one. Soft Stone keeps the
part that's genuinely beautiful — a single continuous material, lit from one
direction, that objects are pushed out of or pressed into — and fixes the part
that made it unusable.

**The rule that makes it work: relief encodes structure, never meaning.**

Elevation tells you what is a surface, what is a container, what is a control.
It never tells you what is selected, what is urgent, what is done, or what is
disabled. Those are always carried by contrast, weight, colour or a glyph.
Consequence: flatten every shadow to zero and both apps remain fully usable.
We test this — there's a debug flag that does exactly that, and a screenshot
suite that runs in that mode.

---

## 1. The ground

One material, two grounds, per platform appearance.

```
Light   ground   #E9EBF0   warm neutral grey, ~92% L
        raised   #EDEFF4   the surface sits *slightly lighter* than ground
        light    #FFFFFF   top-left highlight
        dark     #C3C7D2   bottom-right shadow
Dark    ground   #22242B   not black — pure black kills the effect entirely
        raised   #282B33
        light    #34373F   in dark mode the "light" is a lifted grey, not white
        dark     #15171C
```

Two notes that matter more than they look:

- **Dark-mode neumorphism fails if you just invert.** A white highlight on a
  dark ground reads as a glow, not a bevel. In dark mode the highlight is a
  desaturated lift of the ground (+8% L) and the shadow goes nearly black. The
  effect gets subtler in dark mode, and that's correct — it should.
- **The ground is warm.** A blue-grey ground (`#E8EBF2`, which is what most
  neumorphism demos use, including our own web apps in this repo) reads cold and
  cheap on OLED. Pulling a few points of yellow into it makes the whole thing
  feel like paper or clay rather than plastic.

## 2. The light source

**Top-left, fixed, always, on every element in both apps.** Non-negotiable —
one inconsistent element and the whole illusion of a physical material breaks.

Practically this means offsets are always `(-x, -y)` for the highlight and
`(+x, +y)` for the shadow, and it means we never mirror the shadow for RTL
layouts (light doesn't flip when the language does).

## 3. The elevation ladder

Five levels. Nothing gets an ad-hoc shadow.

| Level | Name | Use | Highlight | Shadow |
|-------|------|-----|-----------|--------|
| −1 | **carved** | text fields, progress tracks, the well a control sits in | inset 2/4 | inset 3/6 |
| 0 | **flush** | the ground itself, list backgrounds | — | — |
| 1 | **lifted** | rows, chips, secondary buttons | 3/6 blur 8 | 3/6 blur 10 |
| 2 | **raised** | cards, the primary button, the clock face | 6/10 blur 14 | 6/12 blur 18 |
| 3 | **floating** | sheets, popovers, the active alarm | 10/16 blur 24 | 12/20 blur 32 |

Press behaviour: a **lifted** or **raised** control animates to **carved** on
touch-down, over 120ms, and back over 220ms with a slight overshoot. That
transition *is* the button feedback — it's the single best thing about
neumorphism and the reason to use it at all. It also gets a `.impact(.soft)`
haptic on the down transition only, never on the release.

## 4. Where the accessibility fix lives

| Setting | What Soft Stone does |
|---------|----------------------|
| Increase Contrast | Shadows drop to 30% opacity; every surface gains a 1px hairline border at 20% ink; text steps up one weight; accent saturation increases |
| Reduce Transparency | All blur-backed materials become opaque fills |
| Reduce Motion | Elevation changes become instant crossfades; the clock's second hand ticks instead of sweeping; no parallax anywhere |
| Dynamic Type ≥ AX3 | Rows relayout vertically, elevation is retained but padding scales with type; nothing truncates, ever |
| VoiceOver | Elevation is inert (it's decoration). Every control has an explicit label, value, and hint, and the pressed/unpressed state is announced from real state, not from appearance |
| Smart Invert | Surfaces are marked so photos and the clock face don't invert |

Contrast floors, checked in CI against the actual rendered pixels, not the
token values: body text 7:1, secondary text 4.5:1, any glyph carrying meaning
4.5:1, control edges 3:1 with shadows disabled.

## 5. Type

**SF Pro throughout** — a custom typeface here would be a distraction and would
break Dynamic Type. What we do instead is use SF properly, which almost nobody
does:

- Numerals in the clock, timers and counters use `.monospacedDigit()` so nothing
  jitters as the time changes. This is the single most visible "someone cared"
  detail in an alarm app.
- The large clock uses SF Pro Display with tightened tracking (−2%) and
  optical sizing. At 96pt the default tracking looks loose and amateur.
- Exactly three roles: **Title** (semibold, tight), **Body** (regular),
  **Detail** (medium, small caps for metadata like "TOMORROW · 7:30"). Small
  caps for metadata is the trick that makes a minimal UI look typeset rather
  than under-designed.
- Line length caps at 62 characters on iPad and Mac, so text never runs the
  full width of a 15" display.

## 6. Colour discipline

The ground is grey. Ink is a dark warm grey (`#3A3D46`), not black. Secondary
ink is 58% of that. **One accent per app, used in at most three places on any
screen.**

- Cairn: **slate blue** `#5B6BA8` — calm, recedes, doesn't compete with content.
- Aubade: **low amber** `#C98A4B` — warm, works at 3am without hurting, and is
  the colour of the sunrise gradient it shares a screen with.

Semantic colour (a red for a destructive action, a green for a completion) is
allowed but desaturated to sit inside the material — full-saturation system red
on a soft grey ground looks like a bug.

## 7. Motion

One spring, three configurations. Everything in both apps uses one of these.

```swift
enum Motion {
    static let snap   = Animation.spring(response: 0.28, dampingFraction: 0.86)  // controls, presses
    static let settle = Animation.spring(response: 0.44, dampingFraction: 0.82)  // rows, reorder, sheets
    static let drift  = Animation.spring(response: 0.90, dampingFraction: 1.00)  // ambient: gradients, clock
}
```

Rules:
- Motion is **causal**. A sheet scales up from the frame of the control that
  opened it. A completed task doesn't fade — it slides down into the "done"
  well at the bottom of the list, so you can see where it went.
- No animation longer than 500ms on an interactive path, ever.
- Ambient motion (Aubade's dawn gradient) runs at low frequency, pauses when the
  app isn't frontmost, and stops entirely under Low Power Mode.

## 8. Haptics

Tuned per gesture, not sprinkled. A haptic on every tap is noise.

| Event | Feedback |
|-------|----------|
| Button press-down | `.impact(.soft, intensity: 0.5)` |
| Task completed | `.impact(.rigid)` then `.success` 60ms later — a small two-part "click-done" |
| Drag pickup / drop | `.impact(.light)` / `.impact(.medium)` |
| Time-picker detent (each 5 min) | `.selection` |
| Alarm dismissed | `.success`, once |
| Snooze | nothing — you're half asleep, don't buzz at them |

## 9. Platform differentiation

Same design language, three genuinely different apps. This is where "not
vibe-coded" is won or lost.

- **iPhone** — one column, thumb-reachable primary action in the bottom third,
  sheet-based navigation, no toolbar clutter.
- **iPad** — a three-column split view on Cairn (perspectives / list / detail),
  full keyboard shortcut coverage, pointer hover states (surfaces lift 1 level
  on hover), Apple Pencil scribble into the capture field, drag-and-drop of a
  task onto Calendar.
- **Mac** — a real Mac app, not a stretched iPad one: proper `Menu` bar with a
  full command set, a menu-bar extra for capture with a global hotkey, window
  restoration, multiple windows, `Table` for the list view on wide windows,
  and Soft Stone's relief dialed **down 30%** because shadows that read as soft
  on a 6" OLED read as muddy on a 27" display at arm's length.

## 10. Anti-patterns — explicitly banned

- Soft-on-soft text (relief as the only cue for a control)
- More than one accent colour on screen
- Emoji used as interface icons (SF Symbols only, custom-drawn where SF lacks one)
- Gradients on buttons
- A shadow on a shadow (nesting raised inside raised)
- Any element that animates on appearance without the user causing it
- Skeleton loaders — at our data sizes nothing should ever be loading
- A settings screen that is an undifferentiated stack of toggles

---

## Reference implementation sketch

`SoftStone.swift` in this directory is a working sketch of the token layer and
the surface modifier, enough to show the ladder is real and not hand-waving.
