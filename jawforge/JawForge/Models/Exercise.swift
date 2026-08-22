import Foundation

/// One jawline workout. `durationSeconds` drives the in-app timer;
/// `targets` links the exercise back to the metric it helps most.
struct Exercise: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let tagline: String
    let targets: String
    let durationSeconds: Int
    let sets: String
    let steps: [String]
    let caution: String?
}

enum ExerciseCatalog {
    static let all: [Exercise] = [
        Exercise(
            id: "mewing",
            name: String(localized: "Mewing (tongue posture)"),
            icon: "mouth",
            tagline: String(localized: "The foundation — proper resting tongue posture."),
            targets: String(localized: "Lower-face balance · overall definition"),
            durationSeconds: 120,
            sets: String(localized: "Hold 2 min · practice until it's your default"),
            steps: [
                String(localized: "Close your lips, teeth lightly touching or slightly apart."),
                String(localized: "Press the ENTIRE tongue — tip, middle and back — flat against the roof of your mouth."),
                String(localized: "The tip sits just behind the front teeth, not touching them."),
                String(localized: "Breathe through your nose and hold. Your goal is for this to become your resting posture all day."),
            ],
            caution: nil
        ),
        Exercise(
            id: "chin_tucks",
            name: String(localized: "Chin tucks"),
            icon: "arrow.down.to.line",
            tagline: String(localized: "Fixes forward-head posture that hides your jawline."),
            targets: String(localized: "Jaw angle · under-chin area"),
            durationSeconds: 60,
            sets: String(localized: "3 sets × 10 reps"),
            steps: [
                String(localized: "Sit or stand tall, shoulders relaxed, gaze straight ahead."),
                String(localized: "Draw your chin straight back, as if making a double chin on purpose."),
                String(localized: "You should feel a stretch at the base of the skull and tension under the chin."),
                String(localized: "Hold 3 seconds, release. That's one rep."),
            ],
            caution: nil
        ),
        Exercise(
            id: "jaw_resistance",
            name: String(localized: "Resistance press"),
            icon: "hand.raised",
            tagline: String(localized: "Strength work for the muscles that shape the jaw corner."),
            targets: String(localized: "Jaw angle · jaw width"),
            durationSeconds: 90,
            sets: String(localized: "3 sets × 8 slow reps"),
            steps: [
                String(localized: "Place a fist under your chin."),
                String(localized: "Slowly open your mouth while your fist resists the movement."),
                String(localized: "Open over a 3-second count, then close over 3 seconds, keeping tension the whole way."),
                String(localized: "Rest 15 seconds between sets."),
            ],
            caution: String(localized: "Stop if you feel clicking or pain in the jaw joint (TMJ).")
        ),
        Exercise(
            id: "chewing",
            name: String(localized: "Chewing training"),
            icon: "circle.grid.cross",
            tagline: String(localized: "Progressive overload for the masseter — the jaw's 'bicep'."),
            targets: String(localized: "Jaw width · jaw angle"),
            durationSeconds: 300,
            sets: String(localized: "5–10 min · alternate sides evenly"),
            steps: [
                String(localized: "Use a firm sugar-free gum (or mastic gum once conditioned)."),
                String(localized: "Chew with slow, deliberate full closures — quality over speed."),
                String(localized: "Switch sides every minute so both masseters grow evenly."),
                String(localized: "Build up duration over weeks like any other muscle."),
            ],
            caution: String(localized: "Overdoing it causes TMJ soreness — start with 5 minutes a day.")
        ),
        Exercise(
            id: "neck_curls",
            name: String(localized: "Neck curls"),
            icon: "figure.strengthtraining.traditional",
            tagline: String(localized: "Builds the neck that frames a sharp jawline."),
            targets: String(localized: "Under-chin area · overall definition"),
            durationSeconds: 90,
            sets: String(localized: "2 sets × 10 reps"),
            steps: [
                String(localized: "Lie on your back, knees bent, tongue pressed to the roof of your mouth."),
                String(localized: "Tuck your chin, then curl just your head up toward your chest."),
                String(localized: "Lower back down with control. Keep shoulders on the floor."),
                String(localized: "Only the neck moves — no jerking."),
            ],
            caution: String(localized: "Skip this one if you have any neck injury history.")
        ),
        Exercise(
            id: "vowel_stretch",
            name: String(localized: "O-E vowel stretch"),
            icon: "waveform",
            tagline: String(localized: "Dynamic stretch that wakes up the whole lower face."),
            targets: String(localized: "Symmetry · lower-face balance"),
            durationSeconds: 60,
            sets: String(localized: "3 sets × 15 reps"),
            steps: [
                String(localized: "Exaggerate saying \"O\" — lips in a tight round shape."),
                String(localized: "Snap to an exaggerated \"E\" — corners of the mouth pulled wide."),
                String(localized: "Keep every movement symmetric; watch yourself in a mirror."),
                String(localized: "Alternate O-E at one rep per second."),
            ],
            caution: nil
        ),
        Exercise(
            id: "platysma_flex",
            name: String(localized: "Platysma flex"),
            icon: "bolt",
            tagline: String(localized: "Tightens the sheet muscle running from jaw to collarbone."),
            targets: String(localized: "Under-chin area · jaw angle"),
            durationSeconds: 60,
            sets: String(localized: "3 holds × 10 seconds"),
            steps: [
                String(localized: "Tilt your head back slightly and jut the lower jaw forward."),
                String(localized: "Pull the corners of your mouth down hard — the neck bands should pop out."),
                String(localized: "Hold 10 seconds, feeling tension from jawline to collarbone."),
                String(localized: "Relax fully between holds."),
            ],
            caution: nil
        ),
        Exercise(
            id: "side_glide",
            name: String(localized: "Side-to-side glide"),
            icon: "arrow.left.and.right",
            tagline: String(localized: "Evens out left/right imbalance in jaw musculature."),
            targets: String(localized: "Symmetry"),
            durationSeconds: 60,
            sets: String(localized: "2 sets × 12 glides per side"),
            steps: [
                String(localized: "Relax your jaw with lips gently closed."),
                String(localized: "Glide the lower jaw slowly to the left as far as comfortable."),
                String(localized: "Return to center, then glide right. Keep it slow and controlled."),
                String(localized: "If one side feels tighter, give it two extra glides."),
            ],
            caution: String(localized: "Keep the range comfortable — never force the glide.")
        ),
    ]

    static func byID(_ id: String) -> Exercise? {
        all.first { $0.id == id }
    }
}

/// Daily lifestyle habits tracked alongside exercises — the "all-day" work
/// that moves the needle more than any 60-second set. Completion is stored
/// through the same per-day mechanism as exercises.
struct Habit: Identifiable, Equatable {
    let id: String
    let name: String
    let detail: String
    let icon: String
}

enum HabitCatalog {
    static let all: [Habit] = [
        Habit(
            id: "habit_mewing",
            name: String(localized: "All-day tongue posture"),
            detail: String(localized: "Tongue on the roof, lips closed, nasal breathing"),
            icon: "mouth"
        ),
        Habit(
            id: "habit_water",
            name: String(localized: "Drink 2L+ of water"),
            detail: String(localized: "Water retention from dehydration hides definition"),
            icon: "drop"
        ),
        Habit(
            id: "habit_sleep",
            name: String(localized: "Sleep on your back"),
            detail: String(localized: "Side and stomach sleeping press the jaw unevenly"),
            icon: "bed.double"
        ),
        Habit(
            id: "habit_chew",
            name: String(localized: "Chew meals evenly"),
            detail: String(localized: "Alternate sides at every meal for symmetry"),
            icon: "arrow.left.arrow.right"
        ),
    ]
}
