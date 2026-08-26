# Keystone — the sync spine

How Sill stays identical on iPhone, iPad and Mac, and how Aubade survives a new
phone — without a server, an account system, or a subscription to pay for either.

---

## 1. Shape

```
  Sill                                    Aubade
  ┌──────────┐  ┌──────────┐  ┌────────┐   ┌──────────┐
  │  iPhone  │  │   iPad   │  │  Mac   │   │  iPhone  │
  │ SwiftData│  │ SwiftData│  │SwiftData│  │ SwiftData│
  └────┬─────┘  └────┬─────┘  └───┬────┘   └────┬─────┘
       └─────────────┴────────────┘             │
                     │                          │
        CloudKit private DB              CloudKit private DB
        (three-device sync)              (restore only — one
                                          device ever writes)
```

Two apps, two containers, two very different jobs. Sill genuinely syncs: three
devices reading and writing the same list. Aubade has exactly one writer, so its
"sync" is a backup that happens to use the same machinery — no arbitration, no
merge, no concurrency. That asymmetry is the whole reason Aubade is buildable.

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
(and per Sill's concept doc, we won't).

The schema constraints are real and shape the models, so design for them from
day one rather than discovering them at integration time: everything optional
or defaulted, no unique constraints, uniqueness enforced in application code
against a `UUID` we generate ourselves.

## 3. Conflicts, honestly

Last-writer-wins is fine for most fields and quietly wrong for a few. The fix
is to make the wrong cases structurally impossible rather than to fight the
merge engine.

**Sill**

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

**Aubade** — one device writes, so there is nothing to merge. The two rules that
still matter are about *restoring*, not syncing:

| Case | Resolution |
|------|------------|
| Restoring onto a new phone | Alarms arrive **disabled**, and the first launch shows them for confirmation. Silently arming an alarm on a device the user is still setting up is exactly the kind of surprise an alarm clock can't afford. |
| Alarm deleted while it's ringing | Deletion never affects an in-flight ring. The ringing alarm is a local object; it finishes its life. |
| `WakeEvent` history | Not synced at all, not even for restore. See §6. |
| Two devices somehow both writing | Can't happen today. If a Watch app ever makes it possible: **off wins** on a disagreement about enablement — a spurious alarm at 6am is far worse than a missed one you already thought you'd killed. |

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

## 5. Ring arbitration, and why there isn't any

Aubade is iPhone-only, so the hardest problem in an alarm app doesn't exist:
one device holds the schedule, one device rings, one device dismisses. No ring
policy, no bedside detection, no dismissal propagation, no `modifiedBy` field.

That's worth being explicit about, because it was going to be the single
biggest subsystem in the app. The design is kept here rather than deleted, since
a Watch app brings all of it straight back:

> **Device registry.** Each device writes one small `Device` record (id, name,
> form factor, last-seen, `isLikelyBedside`) that every other device reads.
>
> **Bedside detection.** Stationary + charging + screen idle across the sleep
> window means a device volunteers as bedside. Ties break by form factor
> (Watch > iPhone > iPad) then by last-seen.
>
> **Dismissal propagation**, in three layers, because the cost of the failure is
> enormous relative to the cost of the redundancy:
> 1. A Bonjour/`Network.framework` beacon between your own devices on the same
>    Wi-Fi. Sub-second, and works with no internet at all — which covers
>    essentially every bedside scenario.
> 2. A CloudKit silent push as the durable fallback.
> 3. Any device still ringing 90 seconds after another dismissed stops itself
>    regardless. Fail quiet, not fail loud: the failure mode of an alarm app
>    must never be "it wouldn't stop".

For now, the only rule Aubade needs is the one below.

## 5a. Firing is never the network's job

The rule that keeps Aubade trustworthy, and the reason it stays true even as a
single-device app:

> **The phone schedules its own OS-level alarm from local data. Sync only ever
> changes the schedule; it is never in the path of an alarm firing.**

If CloudKit is down, if the user is on a plane, if their iCloud is full — the
alarm still rings. Sync degrades to "your new phone doesn't have your alarms
yet", never to "nothing rang".

The reconciliation loop:

```
on launch, on foreground, on remote-change push, and on a daily
background refresh:
    read the local Alarm set
    diff against the OS-level alarms currently scheduled
    cancel what's gone, schedule what's new, reschedule what moved
```

Idempotent, cheap, and safe to run constantly — which means it does.

## 6. Privacy

Both apps: **no analytics, no crash-reporting SDK, no third-party frameworks
that phone home.** Crash reports come through Apple's own opt-in channel, which
is enough.

- Sill's task text never leaves the device except into the user's own iCloud.
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

- A deterministic two-device simulator harness for **Sill**: apply an ordered
  script of operations to two stores, merge, assert the converged state. Every
  row of Sill's conflict table above is a test case.
- Offline→online: 200 local changes on a device that hasn't seen the network in
  a week, merged against 200 from another. Assert convergence and no data loss.
- Alarm reconciliation fuzzing: random schedule edits, assert the OS-level alarm
  set always matches the local model after the loop runs.
- **The one that matters most**: a scheduled overnight device test that sets a
  real alarm on a real iPhone and asserts it fired — across a reboot, a Focus, a
  Low Power Mode night, and silent mode. Automated where possible; manually,
  weekly, always. An alarm app that doesn't ring is not a bug, it's the end of
  the product.
