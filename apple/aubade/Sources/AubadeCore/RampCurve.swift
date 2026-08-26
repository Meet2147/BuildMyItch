//  RampCurve.swift
//
//  Alarms are jarring because they start at full volume with a hard attack.
//  Aubade's rise shallow for most of the ramp and steep only at the end: the
//  first minutes sit near the threshold of hearing, and the guarantee that
//  you'll actually wake is paid for in the last thirty seconds.

import Foundation

public struct RampCurve: Equatable, Sendable {

    /// Where the ramp opens. Audible in a quiet room, not enough to wake you.
    public var floorLevel: Double
    /// >1 keeps the curve shallow early and steepens it late.
    public var exponent: Double

    public init(floorLevel: Double = 0.15, exponent: Double = 2.6) {
        self.floorLevel = max(0, min(1, floorLevel))
        self.exponent = max(1, exponent)
    }

    /// Volume at a point through the ramp, 0…1 in and 0…1 out.
    public func level(atProgress progress: Double) -> Double {
        let p = max(0, min(1, progress))
        return floorLevel + (1 - floorLevel) * pow(p, exponent)
    }

    public func level(at instant: Date, start: Date, end: Date) -> Double {
        guard end > start else { return 1 }
        let progress = instant.timeIntervalSince(start) / end.timeIntervalSince(start)
        return level(atProgress: progress)
    }

    /// Layers enter one at a time, so the ramp adds *information* rather than
    /// just volume. Waking to something that got busier is gentler than waking
    /// to the same thing shouting.
    public func voices(atProgress progress: Double, maximum: Int = 4) -> Int {
        guard maximum > 0 else { return 0 }
        let p = max(0, min(1, progress))
        // Curved rather than linear, so the second voice doesn't arrive
        // halfway through — the opening minutes should stay uneventful.
        let entered = pow(p, 1.6) * Double(maximum - 1)
        return max(1, min(maximum, Int(entered.rounded(.down)) + 1))
    }

    /// Restarting after a snooze opens louder each time — more honest than
    /// removing snooze, and less rude than starting at full volume.
    public func raisingFloor(by amount: Double) -> RampCurve {
        RampCurve(floorLevel: min(0.7, floorLevel + amount), exponent: exponent)
    }
}
