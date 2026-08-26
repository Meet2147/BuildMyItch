//  SnoozeLadder.swift
//
//  Nine minutes is a mechanical accident from 1956 that everybody inherited.
//  Aubade shortens each snooze and raises the floor it restarts at, so
//  snoozing gets less rewarding rather than being taken away.

import Foundation

public enum SnoozeLadder {

    /// Minutes granted for the nth snooze, counting from zero.
    public static let steps = [12, 8, 5]

    public static func minutes(afterSnoozes count: Int) -> Int {
        guard count >= 0 else { return steps[0] }
        return count < steps.count ? steps[count] : steps[steps.count - 1]
    }

    /// Each restart opens a little louder.
    public static func curve(_ base: RampCurve, afterSnoozes count: Int) -> RampCurve {
        base.raisingFloor(by: 0.12 * Double(max(0, count)))
    }

    /// After this many, it stops offering. Not punishment — at four snoozes
    /// the alarm has failed and the answer is a different alarm, not another
    /// five minutes.
    public static let limit = 4

    public static func isAvailable(afterSnoozes count: Int) -> Bool { count < limit }
}
