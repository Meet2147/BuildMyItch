//  WakeWindowTests.swift
//  The guarantee that matters: never later than the hard time, and never
//  claiming to have detected something it didn't.

import Testing
import Foundation
@testable import AubadeCore

@Suite("Wake window")
struct WakeWindowTests {

    private let hard = Clock.at(2026, 8, 27, 6, 40)
    private var window: ClosedRange<Date> { Clock.at(2026, 8, 27, 6, 20)...hard }
    private var now: Date { Clock.at(2026, 8, 27, 6, 0) }

    @Test("No signal at all means the hard time, and it says so")
    func noSamples() {
        let decision = WakeWindow.decide(window: window, samples: [], now: now)
        #expect(decision.fireAt == hard)
        #expect(decision.usedSignal == false)
    }

    @Test("Faint movement is noise, not a sleep stage")
    func belowThreshold() {
        let samples = [MotionSample(at: Clock.at(2026, 8, 27, 6, 25), intensity: 0.2)]
        let decision = WakeWindow.decide(window: window, samples: samples, now: now)
        #expect(decision.fireAt == hard)
        #expect(decision.usedSignal == false)
    }

    @Test("A real upswing inside the window wins")
    func picksTheUpswing() {
        let samples = [
            MotionSample(at: Clock.at(2026, 8, 27, 6, 24), intensity: 0.4),
            MotionSample(at: Clock.at(2026, 8, 27, 6, 31), intensity: 0.8),
            MotionSample(at: Clock.at(2026, 8, 27, 6, 36), intensity: 0.5),
        ]
        let decision = WakeWindow.decide(window: window, samples: samples, now: now)
        #expect(decision.fireAt == Clock.at(2026, 8, 27, 6, 31))
        #expect(decision.usedSignal)
    }

    @Test("Equally good moments go to the later one — sleep is worth keeping")
    func tiesGoLater() {
        let samples = [
            MotionSample(at: Clock.at(2026, 8, 27, 6, 24), intensity: 0.7),
            MotionSample(at: Clock.at(2026, 8, 27, 6, 34), intensity: 0.7),
        ]
        #expect(WakeWindow.decide(window: window, samples: samples, now: now).fireAt
                == Clock.at(2026, 8, 27, 6, 34))
    }

    @Test("Movement outside the window is not our business")
    func ignoresOutside() {
        let samples = [MotionSample(at: Clock.at(2026, 8, 27, 5, 50), intensity: 0.9)]
        #expect(WakeWindow.decide(window: window, samples: samples, now: now).fireAt == hard)
    }

    @Test("Readings from before now can't be acted on")
    func ignoresThePast() {
        let later = Clock.at(2026, 8, 27, 6, 33)
        let samples = [MotionSample(at: Clock.at(2026, 8, 27, 6, 25), intensity: 0.9)]
        #expect(WakeWindow.decide(window: window, samples: samples, now: later).fireAt == hard)
    }

    @Test("A zero-width window always returns the hard time")
    func zeroWidth() {
        let decision = WakeWindow.decide(window: hard...hard, samples: [
            MotionSample(at: hard, intensity: 1.0)
        ], now: now)
        #expect(decision.fireAt == hard)
        #expect(decision.usedSignal == false)
    }
}
