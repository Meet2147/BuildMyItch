# 🪨 Sill

> *sill* (n.) — the ledge beneath a window, where you set things down and
> where the morning light lands. Also, in geology, a sheet of stone that
> intruded sideways between older layers.

**A todo app that plans your day for you, then gets out of the way.**

---

## 1. The thesis

Every todo app asks you to do two jobs: *capture* what needs doing, and
*decide* what to do now. Capture is easy and every app is good at it. Deciding
is the hard part, and almost every app punts it back to you — here are your
tags, your priorities, your four projects, your 87 overdue items, good luck.

The result is a well-documented failure mode: the list becomes a monument to
everything you haven't done, you stop opening it, and you go back to a notes
file.

Sill takes the deciding job. You throw things in with no structure at all.
Once a day it produces **one screen: today**, with a realistic number of things
on it, ordered by when you're actually capable of doing them. Everything else
is deliberately hard to look at.

### Three principles

1. **Today is the app.** Not a view of the app — the app. Other screens exist,
   but you have to go looking for them.
2. **Capture costs nothing, structure costs nothing.** You never have to pick a
   project, a tag, or a priority. You type a sentence. If it contains structure,
   we extract it. If it doesn't, it goes in the pile and Sill figures it out.
3. **The backlog is not a debt.** Nothing goes red. Nothing accumulates an
   overdue count. An old task gets quieter, not louder, and eventually Sill
   asks you once whether it's still real.

## 2. What "smart" actually means here

Not a chatbot. Four specific behaviours, all on-device.

### 2.1 Sentence-in, task-out

You type one line. The on-device model turns it into structure.

```
"call dentist about the crown thing tomorrow morning"
   → Call dentist about the crown   ·  Tue AM  ·  ~10 min  ·  phone  ·  errands

"finish the Q3 deck before the Thursday review"
   → Finish Q3 deck  ·  due Wed EOD (backdated from Thu)  ·  ~2h  ·  deep work

"pick up parcel, gym, book flights, reply to Sam"
   → four separate tasks, each sized and typed
```

The last one matters more than it looks: **one line can become several tasks.**
Nobody thinks in single tasks; people think in dumps. Handling a comma-separated
brain-dump correctly is the difference between "capture" and "typing into a form".

Everything is a suggestion rendered inline as editable chips. Tap any chip to
change it. Nothing is ever silently assigned.

### 2.2 Energy, not priority

Priority flags fail because everything becomes P1. Sill classifies by **shape
of attention required**, which is observable and doesn't inflate:

| Type | Meaning | When it gets scheduled |
|------|---------|------------------------|
| **Deep** | needs an uninterrupted hour+ | your best focus window, at most 2/day |
| **Admin** | short, boring, low stakes | batched into one afternoon block |
| **Errand** | requires being somewhere | grouped by location |
| **Social** | requires another person | inside their working hours |
| **Idle** | can be done while queueing | surfaced on the widget, never scheduled |

This is the load-bearing idea. It's also the one that makes the app feel
intelligent without any UI for intelligence.

### 2.3 A day that fits

Sill reads your calendar (read-only, EventKit) and knows how much unscheduled
time you actually have. If today has 90 free minutes, today gets 90 minutes of
tasks. Not eleven items — three.

The plan appears as a soft vertical rhythm, not a Gantt chart:

```
   this morning     ▸ Finish Q3 deck               2h   deep
   ─────────────────────────────────────────────────────────
   after lunch      ▸ Reply to Sam                10m   social
                    ▸ Expenses                    15m   admin
                    ▸ Chase invoice               10m   admin
   ─────────────────────────────────────────────────────────
   whenever         ▸ Pick up parcel                    errand
```

Drag a task between bands to re-plan; the rest reflows. That's the entire
planning interface.

### 2.4 It learns two things only

We are extremely conservative here, because a todo app that guesses wrong is
worse than one that doesn't guess.

- **When you actually do deep work.** From completion timestamps. After ~two
  weeks it stops putting your hardest task at 9am if you've never once completed
  one before 11.
- **How badly you estimate.** If your "30 min" tasks take 50, it silently
  multiplies your estimates by 1.6 when it plans the day — and never shows you
  that number, because seeing it would just be demoralising.

Explicitly **not** learned: what you should be working on, what's important,
anything requiring a model of your goals. That's not an app's business.

## 3. Screens

### Today — the home screen

A carved well down the middle of a soft grey ground. Time bands as small-caps
labels. Tasks as lifted rows.

- **Completion**: swipe right, or tap the circle. The row does the two-part
  haptic, the text sets in weight rather than striking through, and the row
  slides down into a **done well** at the bottom of the screen that shows a
  simple count. Nothing vanishes — you can see your day accumulate.
- **The count is the reward.** No streaks, no confetti, no XP. A small carved
  counter that reads `4 done` and resets at your wake time.
- **Empty state**: a single line of real writing, and the day's remaining free
  time. `Nothing left. You've got 3 hours back.`

### Capture — one field, everywhere

The most-used surface in the app, so it's the most designed one.

- iPhone: a persistent carved field pinned above the tab area. It never scrolls
  away. `⌘N` on hardware keyboards.
- Mac: a menu-bar extra with a global hotkey (default `⌃Space`), a 420pt
  panel that opens under the menu bar with the field already focused, and
  closes on `Esc` or commit. **This is the single feature that makes the Mac app
  worth buying.**
- iPad: same field, plus Scribble, plus drag-and-drop of text from any app.
- Everywhere: `⌘⇧V` pastes clipboard straight into a task; a share sheet
  extension turns any URL, mail message or selected text into a task with a
  back-link.

Parse preview appears *below* the field as chips as you type, with a 300ms
debounce so it doesn't flicker on every keystroke.

### The Pile — everything else

Not called "Inbox" (implies obligation) or "All Tasks" (implies a database).
Deliberately plain: a single flat list, newest first, no folders, no projects.
Search is fast and full-text. There's one grouping control — by type — and
that's it.

Old items lose contrast on a curve. At 30 days a task fades to the point where
Sill asks, once, on a quiet card: *"Still real?"* → **Keep / Let go**. Letting
go is not deleting; it goes to a "let go" archive you never have to see.
This is the anti-guilt mechanism and it's a real feature, not a gimmick.

### Someday — the good backlog

Things with no date that you actually want to do. Rendered completely
differently: a loose grid of small cards rather than a list, because it should
feel like browsing, not processing.

### Review — 90 seconds on Sunday

Optional, opt-in, one screen. What you finished (by type, as a small stacked
bar), what you let go, what's still waiting, and one prompt: *pick three things
that matter this week.* Those three get a quiet pin in the Today header all
week. That's the entire weekly-review feature.

## 4. Platform surfaces

Where the app actually lives.

| Surface | What it does |
|---------|--------------|
| **Lock Screen widget** | Next task, and only the next one |
| **Home Screen widget (S)** | Today's count + next task; tap-to-complete inline |
| **Home Screen widget (M)** | The three time bands, interactive completion |
| **Control Center control** | Quick capture — one tap from anywhere in iOS |
| **Live Activity** | Optional focus session for a Deep task: elapsed time in the Dynamic Island, stop from the Lock Screen |
| **Watch complication** | Next task + count. Complete from the wrist |
| **Siri / Shortcuts** | Full App Intents coverage: add, complete, query "what's next", "how much is left today" |
| **Spotlight** | Tasks indexed, actionable from search results |
| **Menu bar (Mac)** | Capture panel + next-task glance |
| **Focus filters** | Work Focus hides personal tasks and vice versa, set up once |

## 5. Deliberately not doing

Writing this list down is what keeps the app small.

- ❌ Collaboration, sharing, assigning. It's a personal app. This is a hard no —
  it's the single decision that keeps the whole thing simple.
- ❌ Projects, sub-projects, nested subtasks. One flat level. A task with 8
  subtasks is 8 tasks.
- ❌ Tags. Type + date is enough structure for a personal list.
- ❌ Streaks, points, gamification of any kind.
- ❌ Notes/wiki features. It's not a second brain, it's a list.
- ❌ Web app, Android, Windows. Apple-only is a positioning decision, not a
  limitation — it's what buys us AlarmKit-class integration and a design that
  doesn't have to survive three platforms' conventions.
- ❌ Natural-language *chat*. Sentence-in-task-out, not a conversation.

## 6. Data model (sketch)

```swift
@Model final class Task {
    var id: UUID
    var title: String
    var note: String?
    var type: TaskType          // deep / admin / errand / social / idle
    var estimate: Duration?     // model's guess, user-editable
    var due: Date?              // hard deadline, rare
    var plannedBand: Band?      // morning / afternoon / evening / whenever
    var plannedDay: Date?
    var completedAt: Date?
    var letGoAt: Date?
    var recurrence: Rule?       // after-completion by default, not fixed-interval
    var sourceURL: URL?         // back-link from share sheet
    var createdAt: Date
    var modifiedAt: Date
}
```

Two notes:
- **Recurrence defaults to after-completion.** "Water the plants every 5 days"
  means 5 days after you last did it, not every 5th calendar day. Fixed-interval
  recurrence is the number one source of overdue-guilt in every other app.
- No `priority` field exists. On purpose.

## 7. Build order

1. Local-only Today + Pile + capture with hand-written parsing (dates only). Usable in ~2 weeks.
2. Soft Stone applied properly; Dynamic Type + VoiceOver pass.
3. CloudKit sync (see `../architecture/SYNC.md`).
4. On-device model for capture; type classification.
5. Calendar-aware day fitting.
6. Widgets, App Intents, Control Center.
7. Mac menu-bar capture. Watch app.
8. Estimate calibration + Review.

The app should be genuinely good and shippable at step 3. Everything after is
what makes it worth paying for.
