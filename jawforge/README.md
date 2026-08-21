# 🦴 JawForge — iOS jawline scanner & coach

Scan your face with the front camera, get an on-device jawline analysis, and
follow a personalized daily training routine to sharpen it.

Unlike the rest of this repo (web apps), JawForge is a **native SwiftUI iOS
app** — open `JawForge.xcodeproj` in Xcode and run.

**Design**: full neumorphic ("soft UI") system — one pale surface tone
(`#E3E8F2`) with depth carved by paired light/dark shadows (`NeuRaised`,
`NeuInset`, `NeuButtonStyle` in `Theme.swift`), a teal→violet gradient
reserved for the single call-to-action per screen, and an animated scan
experience (pulsing face guide, sweeping scan line, staged
"Detecting → Tracing → Measuring → Scoring" analysis overlay).

**Monetization**: freemium with a **JawForge Pro** subscription.
Free = 1 scan/week, 3-scan history, standard routine. Pro = unlimited scans,
full history + trends, adaptive routine, complete metric breakdowns, smart
reminders. Plans: $3.99/wk · $29.99/yr (7-day free trial, anchor) · $79.99
lifetime. The paywall (`PaywallView.swift`) ships with a demo purchase flow;
`Entitlements.swift` marks exactly where StoreKit 2 goes live.

## What it does

1. **Scan** — take a selfie (guided by a face-alignment overlay) or pick a
   photo from your library. Apple's **Vision** framework traces 60+ facial
   landmarks entirely on-device; the photo is analyzed and discarded — nothing
   is uploaded, only the numbers are saved.
2. **Measure** — four jawline metrics, each scored 0–100 and explained in
   plain language:
   | Metric | What it is | Ideal band |
   |---|---|---|
   | Jaw angle | Gonial-angle proxy at the jaw corner (ramus vs. jaw body) | 112–127° |
   | Jaw width | Jaw-corner width ÷ upper-face width | 80–94% |
   | Lower-face balance | Nose→chin height ÷ eyes→chin height | ~50% |
   | Symmetry | How evenly the jaw sits around the facial midline | 92%+ |

   These blend into one **Jawline Score** (angle and symmetry weighted
   heaviest).
3. **Coach** — the guidance engine turns your weakest metrics into a game
   plan ("sharpen your jaw angle", "even out left/right balance", …), each tip
   linked to the exercises that address it, plus the two honest fundamentals:
   body-fat percentage and posture.
4. **Train** — an 8-exercise library (mewing, chin tucks, resistance press,
   chewing training, neck curls, O-E stretch, platysma flex, side glide) with
   step-by-step instructions, per-exercise timers, TMJ cautions, daily
   check-offs and a streak.
5. **Track** — every saved scan charts your score over time (Swift Charts),
   with a since-first-scan delta.

## Project layout

```
JawForge/
  JawForgeApp.swift          App entry (light scheme for neumorphism)
  Theme.swift                Neumorphic design system: palette + NeuRaised/
                             NeuInset/NeuButtonStyle/NeuPrimaryButton
  Models/
    JawlineMetrics.swift     Raw measurements → banded 0–100 scores
    FaceScan.swift           One saved scan (metrics only, no photo)
    Exercise.swift           The 8-exercise catalog
    UserProfile.swift        Onboarding quiz answers (age, lifestyle, goal…)
    ScanStore.swift          @Observable state + JSON persistence + streak
  Services/
    FaceAnalyzer.swift       Vision landmarks → metrics (pure geometry)
    CameraService.swift      AVCaptureSession front-camera wrapper
    GuidanceEngine.swift     Metrics + profile → recommendations + routine
    Entitlements.swift       Pro state, plans, free-tier limits (StoreKit 2 stub)
  Views/
    RootView.swift           Tabs: Scan / Train / Progress (+ onboarding, paywall)
    OnboardingFlowView.swift 5-screen quiz: welcome, about you, lifestyle,
                             training, goal — every answer feeds the engine
    PaywallView.swift        JawForge Pro paywall (3 plans, feature list)
    ScanView.swift           Live preview, animated scan overlay, photo picker
    ResultsView.swift        Score ring, metric breakdown, game plan
    PlanView.swift           Today's routine, streak, exercise library
    ExerciseDetailView.swift Steps + countdown timer (auto-marks complete)
    HistoryView.swift        Score chart + scan list (history gated for free)
```

## Requirements & running

- **Xcode 16+** (the project uses the folder-synchronized project format),
  iOS 17+ deployment target, iPhone only.
- Open `jawforge/JawForge.xcodeproj`, select your team under
  *Signing & Capabilities* if running on a device, and hit Run.
- **Simulator**: there's no camera, so use the photo-library button on the
  Scan tab — drop a selfie into the simulator first (drag a photo onto the
  simulator window).

No dependencies, no backend, no accounts — 100% on-device.

## How the analysis works

`FaceAnalyzer` runs `VNDetectFaceLandmarksRequest`, takes the largest detected
face, and does plain geometry on the returned landmark constellation:

- The **face contour** (ear → chin → ear) gives the chin (lowest point), the
  jaw corners (~15% in from each end), and the face-width endpoints.
- The **gonial-angle proxy** is the angle at each jaw corner between the ray
  toward the contour end (ramus direction) and the ray toward the chin (jaw
  body), averaged over both sides.
- **Eye centers** define the midline and the eye-line for vertical
  proportions; the **nose base** splits the lower face.
- **Symmetry** blends jaw-corner equidistance from the midline with chin
  centering.

Scores use banded mapping: 100 inside the ideal band, falling linearly toward
the band floor. It's deliberately a *frontal-photo estimate* — lighting, head
tilt and expression move the numbers, which is why the app tells users to
re-scan under similar conditions and watch the trend.

## Honest limitations (also stated in-app)

- Bone structure is genetic; exercises affect muscle, posture, and habits —
  the app says so during onboarding and never promises bone remodeling.
- Jawline *visibility* is mostly body-fat percentage; the guidance engine
  puts that front and center rather than burying it.
- Not medical advice; every jaw-loading exercise carries a TMJ caution.
