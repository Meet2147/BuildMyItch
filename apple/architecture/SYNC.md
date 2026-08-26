# Keystone — the sync spine

How Cairn and Aubade stay identical on iPhone, iPad, Mac and Watch without a
server, an account system, or a subscription to pay for either.

---

## 1. Shape

```
        ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
        │  iPhone  │   │   iPad   │   │   Mac    │   │  Watch   │
        │ SwiftData│   │ SwiftData│   │ SwiftData│   │ SwiftData│
        └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
             └──────────────┴───────┬──────┴──────────────┘
                                    │
                        CloudKit private database
                     (user's own iCloud, one container per app)
```

- **Local store**: SwiftData. Every read in the UI is local; the network is
  never in the path of a user interaction.
- **Transport**: CloudKit private database via SwiftData's CloudKit mirroring.
- **Identity**: the user's Apple Account. We never see it, never store it, and
  there is no login screen in either app.
- **Cost to us**: zero. Private-database storage is billed to the user's iCloud
  quota, and our data is kilobytes.

This choice is doing a lot of work: it removes accounts, password reset, GDPR
data-processor obligations, server hosting, and the entire reason most indie
apps end up on a subscription.

## 2. SwiftData mirroring vs. CKSyncEngine

| | SwiftData + CloudKit mirroring | Raw CKSyncEngine |
|---|---|---|
| Effort | Almost none | Weeks |
| Conflict control | Last-writer-wins, no hook | Full control per record |
| Schema constraints | No `@Attribute(.unique)`, all properties need defaults, all relationships optional | None |
| Sharing later | Harder | Native |

**Decision: mirroring for both apps, at least through v1.** Neither app has
concurrent multi-user editing; the conflict surface is one person on four
devices, which is small and mostly benign. Reassess only if we ever add sharing
(and per Cairn's concept doc, we won't).

The schema constraints are real and shape the models, so design for them from
day one rather than discovering them at integration time: everything optional
or defaulted, no unique constraints, uniqueness enforced in application code
against a `UUID` we generate ourselves.

## 3. Conflicts, honestly

Last-writer-wins is fine for most fields and quietly wrong for a few. The fix
is to make the wrong cases structurally impossible rather than to fight the
merge engine.

**Cairn**

| Case | Resolution |
|------|------------|
| Same task edited on two devices | LWW on `modifiedAt`. A title losing a word is a survivable outcome. |
| Completed on phone, edited on Mac | Completion wins — `completedAt` is only ever set, never cleared by a merge. |
| Deleted on one, edited on another | Deletes are soft (`letGoAt`). A soft delete plus an edit resolves to "still exists, still let go" — recoverable, and never a surprise data loss. |
| Two devices both plan today | The plan is derived, not stored. Only user-made overrides sync, so there is nothing to conflict. |

That last row is the important design move: **derive as much as possible so
there's less to sync.** The day plan is recomputed on each device from tasks +
calendar. It's deterministic given the same inputs, so all devices agree without
any of them writing anything.

**Aubade**

| Case | Resolution |
|------|------------|
| Alarm time edited on two devices | LWW, plus `modifiedBy` shown in the UI: *"Changed on your iPad, 11:04pm"*. When it matters this much, tell the user rather than resolving silently. |
| Toggled off on phone, on on Mac | **Off wins.** Asymmetric on purpose: a spurious alarm at 6am is far worse than a missed one you already thought you'd turned off. |
| Alarm deleted while it's ringing | Deletion never affects an in-flight ring. The ringing alarm is a local object; it finishes its life on the device. |
| `WakeEvent` history | Not synced at all. See §6. |

## 4. Firing is never the network's job

The rule that keeps Aubade trustworthy:

> **Every device schedules its own OS-level alarm from local data. Sync only
> changes the schedule; it is never in the path of an alarm firing.**

If CloudKit is down, if the user is on a plane, if their iCloud is full — every
device still rings on the last schedule it knew about. Sync degrades to
"your devices disagree about the schedule", never to "nothing rang".

The reconciliation loop on each device:

```
on launch, on foreground, on remote-change push, and on a daily
background refresh:
    read the synced Alarm set
    diff against the OS-level alarms this device currently holds
    cancel what's gone, schedule what's new, reschedule what moved
```

Idempotent, cheap, and safe to run constantly — which means it does.

## 5. Ring arbitration

Covered in [`../aubade/CONCEPT.md`](../aubade/CONCEPT.md) §6; the sync-relevant
parts:

- **Device registry**: each device writes one small `Device` record (id, name,
  form factor, last-seen, `isLikelyBedside`). Every device reads it. This is the
  only record type either app writes automatically.
- **Bedside detection**: stationary + charging + screen idle across the sleep
  window → this device volunteers as bedside. Ties broken by form factor
  (Watch > iPhone > iPad > Mac) then by last-seen.
- **Dismissal propagation** does *not* go through CloudKit as its primary path.
  A Bonjour/`Network.framework` beacon on the local network handles the
  common case in sub-second time with no internet at all; a CloudKit silent push
  is the durable fallback; and any device ringing >90 seconds stops itself
  regardless. Three layers because the cost of the failure is enormous relative
  to the cost of the redundancy.

## 6. Privacy

Both apps: **no analytics, no crash-reporting SDK, no third-party frameworks
that phone home.** Crash reports come through Apple's own opt-in channel, which
is enough.

- Cairn's task text never leaves the device except into the user's own iCloud.
  On-device parsing means task content is never sent anywhere for processing.
- Aubade's sleep-timing data (`WakeEvent`) is **local-only and never synced.**
  It's the most sensitive data either app holds and no feature needs it to be
  portable. A device restore loses your wake history, and that's an acceptable
  trade.
- Health data (heart rate for wake detection) is read via HealthKit with the
  narrowest possible scope, used in-memory, and never persisted or written back.
- The privacy label for both apps should read "Data Not Collected". Getting to
  literally that label is a design constraint, not an aspiration.

## 7. Shared code

```
Keystone/                 SPM package, shared by both apps
  SoftStone/              design tokens, surfaces, motion, haptics
  Sync/                   SwiftData container setup, remote-change plumbing,
                          device registry, reconciliation loop
  Surfaces/               widget + App Intent helpers shared by both
```

Widgets and extensions read the same store through an **App Group** container,
so a widget never re-syncs or holds its own copy — it opens the same SwiftData
store read-only.

## 8. What we test

Sync bugs are invisible until they're catastrophic, so the test surface is
weighted toward it:

- A deterministic two-device simulator harness: apply an ordered script of
  operations to two stores, merge, assert the converged state. Every row of the
  conflict tables above is a test case.
- Offline→online: 200 local changes on a device that hasn't seen the network in
  a week, merged against 200 from another. Assert convergence and no data loss.
- Alarm reconciliation fuzzing: random schedule edits across devices, assert
  the OS-level alarm set on each device always matches its local model.
- **The one that matters most**: a scheduled overnight device test that sets a
  real alarm on real hardware and asserts it fired. Automated where possible,
  manually, weekly, always. An alarm app that doesn't ring is not a bug, it's
  the end of the product.
