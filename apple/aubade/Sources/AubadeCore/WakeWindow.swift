//  WakeWindow.swift
//
//  Choosing the moment inside the window.
//
//  The honest part of this file is what it does when it has nothing to go on.
//  A phone across the room cannot detect your sleep, and pretending otherwise
//  is the kind of lie that makes an app feel cheap — so with no usable signal
//  it returns the hard time and the setup screen says as much.

import Foundation

/// One reading of how much you moved. Whatever produced it — the phone on the
/// mattress, or a watch — it arrives here as an intensity between 0 and 1.
public struct MotionSample: Equatable, Sendable {
    public var at: Date
    /// 0 = completely still (deep sleep), 1 = moving about (nearly awake).
    public var intensity: Double

    public init(at: Date, intensity: Double) {
        self.at = at
        self.intensity = max(0, min(1, intensity))
    }
}

public enum WakeWindow {

    /// Below this, movement is noise rather than a sleep-stage upswing, and
    /// waking someone on it would be worse than waiting for the hard time.
    public static let threshold = 0.35

    public struct Decision: Equatable, Sendable {
        public var fireAt: Date
        /// False when we fell back to the hard time. The UI never claims to
        /// have detected something it didn't.
        public var usedSignal: Bool
    }

    public static func decide(
        window: ClosedRange<Date>,
        samples: [MotionSample],
        now: Date
    ) -> Decision {
        let hard = window.upperBound

        // A zero-width window is an ordinary alarm, and that's a valid choice.
        guard window.lowerBound < hard else {
            return Decision(fireAt: hard, usedSignal: false)
        }

        let usable = samples.filter {
            window.contains($0.at) && $0.at >= now && $0.intensity >= threshold
        }
        guard !usable.isEmpty else {
            return Decision(fireAt: hard, usedSignal: false)
        }

        // Strongest upswing wins; ties go to the later one, because every
        // minute of sleep we don't take is a minute earned.
        let best = usable.max { lhs, rhs in
            lhs.intensity == rhs.intensity ? lhs.at < rhs.at : lhs.intensity < rhs.intensity
        }
        guard let best else { return Decision(fireAt: hard, usedSignal: false) }

        // Belt and braces: never after the hard time, whatever the data says.
        return Decision(fireAt: min(best.at, hard), usedSignal: true)
    }
}
