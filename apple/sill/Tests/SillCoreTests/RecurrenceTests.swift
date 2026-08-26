//  RecurrenceTests.swift
//  Recurrence after completion is the anti-guilt mechanism. If this is wrong,
//  the app grows the exact overdue pile it exists to avoid.

import Testing
import Foundation
@testable import SillCore

@Suite("Recurrence")
struct RecurrenceTests {

    @Test("Five days means five days after you did it, not every fifth of the month")
    func afterCompletion() {
        let next = Recurrence.every(5).nextDay(after: Clock.date(2026, 8, 26, 14, 0), calendar: Clock.calendar)
        #expect(next == Clock.day(2026, 8, 31))
    }

    @Test("Doing it late just moves the next one late — nothing stacks up")
    func lateCompletionDoesNotStack() {
        let onTime = Recurrence.every(7).nextDay(after: Clock.day(2026, 8, 26), calendar: Clock.calendar)
        let late = Recurrence.every(7).nextDay(after: Clock.day(2026, 8, 29), calendar: Clock.calendar)
        #expect(onTime == Clock.day(2026, 9, 2))
        #expect(late == Clock.day(2026, 9, 5))
    }

    @Test("A fixed weekday finds the next one")
    func fixedWeekday() {
        // Wednesday 26th, recurring on Tuesday.
        let next = Recurrence.everyWeekday(3).nextDay(after: Clock.day(2026, 8, 26), calendar: Clock.calendar)
        #expect(next == Clock.day(2026, 9, 1))
    }

    @Test("Completing on the day itself moves to the following week, not to today")
    func fixedWeekdayOnTheDay() {
        // Wednesday 26th, recurring on Wednesday.
        let next = Recurrence.everyWeekday(4).nextDay(after: Clock.day(2026, 8, 26), calendar: Clock.calendar)
        #expect(next == Clock.day(2026, 9, 2))
    }
}
