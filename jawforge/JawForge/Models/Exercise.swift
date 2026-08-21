import Foundation

/// One jawline workout. `durationSeconds` drives the in-app timer;
/// `targets` links the exercise back to the metric it helps most.
struct Exercise: Identifiable, Codable, Equatable {
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
            name: "Mewing (tongue posture)",
            icon: "mouth",
            tagline: "The foundation — proper resting tongue posture.",
            targets: "Lower-face balance · overall definition",
            durationSeconds: 120,
            sets: "Hold 2 min · practice until it's your default",
            steps: [
                "Close your lips, teeth lightly touching or slightly apart.",
                "Press the ENTIRE tongue — tip, middle and back — flat against the roof of your mouth.",
                "The tip sits just behind the front teeth, not touching them.",
                "Breathe through your nose and hold. Your goal is for this to become your resting posture all day.",
            ],
            caution: nil
        ),
        Exercise(
            id: "chin_tucks",
            name: "Chin tucks",
            icon: "arrow.down.to.line",
            tagline: "Fixes forward-head posture that hides your jawline.",
            targets: "Jaw angle · submental (under-chin) area",
            durationSeconds: 60,
            sets: "3 sets × 10 reps",
            steps: [
                "Sit or stand tall, shoulders relaxed, gaze straight ahead.",
                "Draw your chin straight back, as if making a double chin on purpose.",
                "You should feel a stretch at the base of the skull and tension under the chin.",
                "Hold 3 seconds, release. That's one rep.",
            ],
            caution: nil
        ),
        Exercise(
            id: "jaw_resistance",
            name: "Resistance press",
            icon: "hand.raised",
            tagline: "Strength work for the muscles that shape the jaw corner.",
            targets: "Jaw angle · jaw width",
            durationSeconds: 90,
            sets: "3 sets × 8 slow reps",
            steps: [
                "Place a fist under your chin.",
                "Slowly open your mouth while your fist resists the movement.",
                "Open over a 3-second count, then close over 3 seconds, keeping tension the whole way.",
                "Rest 15 seconds between sets.",
            ],
            caution: "Stop if you feel clicking or pain in the jaw joint (TMJ)."
        ),
        Exercise(
            id: "chewing",
            name: "Chewing training",
            icon: "circle.grid.cross",
            tagline: "Progressive overload for the masseter — the jaw's 'bicep'.",
            targets: "Jaw width · jaw angle",
            durationSeconds: 300,
            sets: "5–10 min · alternate sides evenly",
            steps: [
                "Use a firm sugar-free gum (or mastic gum once conditioned).",
                "Chew with slow, deliberate full closures — quality over speed.",
                "Switch sides every minute so both masseters grow evenly.",
                "Build up duration over weeks like any other muscle.",
            ],
            caution: "Overdoing it causes TMJ soreness — start with 5 minutes a day."
        ),
        Exercise(
            id: "neck_curls",
            name: "Neck curls",
            icon: "figure.strengthtraining.traditional",
            tagline: "Builds the neck that frames a sharp jawline.",
            targets: "Under-chin area · overall definition",
            durationSeconds: 90,
            sets: "2 sets × 10 reps",
            steps: [
                "Lie on your back, knees bent, tongue pressed to the roof of your mouth.",
                "Tuck your chin, then curl just your head up toward your chest.",
                "Lower back down with control. Keep shoulders on the floor.",
                "Only the neck moves — no jerking.",
            ],
            caution: "Skip this one if you have any neck injury history."
        ),
        Exercise(
            id: "vowel_stretch",
            name: "O-E vowel stretch",
            icon: "waveform",
            tagline: "Dynamic stretch that wakes up the whole lower face.",
            targets: "Symmetry · lower-face balance",
            durationSeconds: 60,
            sets: "3 sets × 15 reps",
            steps: [
                "Exaggerate saying \"O\" — lips in a tight round shape.",
                "Snap to an exaggerated \"E\" — corners of the mouth pulled wide.",
                "Keep every movement symmetric; watch yourself in a mirror.",
                "Alternate O-E at one rep per second.",
            ],
            caution: nil
        ),
        Exercise(
            id: "platysma_flex",
            name: "Platysma flex",
            icon: "bolt",
            tagline: "Tightens the sheet muscle running from jaw to collarbone.",
            targets: "Under-chin area · jaw angle",
            durationSeconds: 60,
            sets: "3 holds × 10 seconds",
            steps: [
                "Tilt your head back slightly and jut the lower jaw forward.",
                "Pull the corners of your mouth down hard — the neck bands should pop out.",
                "Hold 10 seconds, feeling tension from jawline to collarbone.",
                "Relax fully between holds.",
            ],
            caution: nil
        ),
        Exercise(
            id: "side_glide",
            name: "Side-to-side glide",
            icon: "arrow.left.and.right",
            tagline: "Evens out left/right imbalance in jaw musculature.",
            targets: "Symmetry",
            durationSeconds: 60,
            sets: "2 sets × 12 glides per side",
            steps: [
                "Relax your jaw with lips gently closed.",
                "Glide the lower jaw slowly to the left as far as comfortable.",
                "Return to center, then glide right. Keep it slow and controlled.",
                "If one side feels tighter, give it two extra glides.",
            ],
            caution: "Keep the range comfortable — never force the glide."
        ),
    ]

    static func byID(_ id: String) -> Exercise? {
        all.first { $0.id == id }
    }
}
