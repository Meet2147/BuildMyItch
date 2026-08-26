//  RampTests.swift

import Testing
import Foundation
@testable import AubadeCore

@Suite("Ramp and snooze")
struct RampTests {

    private let curve = RampCurve()

    @Test("It opens below waking and finishes at full")
    func endpoints() {
        #expect(abs(curve.level(atProgress: 0) - curve.floorLevel) < 0.0001)
        #expect(abs(curve.level(atProgress: 1) - 1.0) < 0.0001)
    }

    @Test("Shallow for most of the way, steep at the end")
    func shape() {
        // Three fifths through, still under half volume.
        #expect(curve.level(atProgress: 0.6) < 0.5)
        // The last tenth carries a big share of the climb.
        let lastTenth = curve.level(atProgress: 1.0) - curve.level(atProgress: 0.9)
        let firstTenth = curve.level(atProgress: 0.1) - curve.level(atProgress: 0.0)
        #expect(lastTenth > firstTenth * 5)
    }

    @Test("Never goes backwards, and never leaves 0…1")
    func monotonicAndClamped() {
        var previous = -1.0
        for step in 0...20 {
            let level = curve.level(atProgress: Double(step) / 20)
            #expect(level >= previous)
            #expect(level >= 0 && level <= 1)
            previous = level
        }
        #expect(curve.level(atProgress: -5) == curve.level(atProgress: 0))
        #expect(curve.level(atProgress: 5) == curve.level(atProgress: 1))
    }

    @Test("Voices enter one at a time, and the opening stays uneventful")
    func voices() {
        #expect(curve.voices(atProgress: 0) == 1)
        #expect(curve.voices(atProgress: 0.4) == 1)
        #expect(curve.voices(atProgress: 1) == 4)

        var previous = 0
        for step in 0...20 {
            let count = curve.voices(atProgress: Double(step) / 20)
            #expect(count >= previous)
            previous = count
        }
    }

    @Test("Snoozes get shorter — twelve, eight, five, and five after that")
    func ladder() {
        #expect(SnoozeLadder.minutes(afterSnoozes: 0) == 12)
        #expect(SnoozeLadder.minutes(afterSnoozes: 1) == 8)
        #expect(SnoozeLadder.minutes(afterSnoozes: 2) == 5)
        #expect(SnoozeLadder.minutes(afterSnoozes: 9) == 5)
    }

    @Test("Each restart opens louder, but the floor is capped")
    func floorRises() {
        let first = SnoozeLadder.curve(RampCurve(), afterSnoozes: 0)
        let third = SnoozeLadder.curve(RampCurve(), afterSnoozes: 2)
        #expect(third.floorLevel > first.floorLevel)
        #expect(SnoozeLadder.curve(RampCurve(), afterSnoozes: 50).floorLevel <= 0.7)
    }

    @Test("It stops offering after four — at that point the alarm has failed")
    func snoozeLimit() {
        #expect(SnoozeLadder.isAvailable(afterSnoozes: 3))
        #expect(SnoozeLadder.isAvailable(afterSnoozes: 4) == false)
    }
}
