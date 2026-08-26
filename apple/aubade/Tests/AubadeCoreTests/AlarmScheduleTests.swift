//  AlarmScheduleTests.swift

import Testing
import Foundation
@testable import AubadeCore

@Suite("Alarm schedule")
struct AlarmScheduleTests {

    @Test("A one-shot alarm rings the next time that clock time comes round")
    func oneShot() {
        let schedule = AlarmSchedule(hour: 6, minute: 40)
        let next = schedule.nextHardTime(after: Clock.night, calendar: Clock.calendar)
        #expect(next == Clock.at(2026, 8, 27, 6, 40))
    }

    @Test("A time already gone today means tomorrow, never today")
    func doesNotRingInThePast() {
        let schedule = AlarmSchedule(hour: 6, minute: 40)
        let morning = Clock.at(2026, 8, 26, 9, 30)
        #expect(schedule.nextHardTime(after: morning, calendar: Clock.calendar) == Clock.at(2026, 8, 27, 6, 40))
    }

    @Test("A repeating alarm skips to its next matching day")
    func repeating() {
        let schedule = AlarmSchedule(hour: 7, minute: 15, days: .weekend)
        // Wednesday night → Saturday.
        #expect(schedule.nextHardTime(after: Clock.night, calendar: Clock.calendar) == Clock.at(2026, 8, 29, 7, 15))
    }

    @Test("Mon–Fri from a Friday night lands on Monday")
    func workweekWrapsTheWeekend() {
        let schedule = AlarmSchedule(hour: 6, minute: 40, days: .workweek)
        let fridayNight = Clock.at(2026, 8, 28, 23, 0)
        #expect(schedule.nextHardTime(after: fridayNight, calendar: Clock.calendar) == Clock.at(2026, 8, 31, 6, 40))
    }

    @Test("The wake window opens exactly `window` minutes before the hard time")
    func windowOpensEarly() {
        let schedule = AlarmSchedule(hour: 6, minute: 40, windowMinutes: 20)
        let window = schedule.nextWakeWindow(after: Clock.night, calendar: Clock.calendar)
        #expect(window?.lowerBound == Clock.at(2026, 8, 27, 6, 20))
        #expect(window?.upperBound == Clock.at(2026, 8, 27, 6, 40))
    }

    @Test("A zero window is an ordinary alarm, and that's allowed")
    func zeroWindow() {
        let schedule = AlarmSchedule(hour: 6, minute: 40, windowMinutes: 0)
        let window = schedule.nextWakeWindow(after: Clock.night, calendar: Clock.calendar)
        #expect(window?.lowerBound == window?.upperBound)
    }

    @Test("Occurrences are materialised locally, so firing never needs a network")
    func upcoming() {
        let daily = AlarmSchedule(hour: 6, minute: 40, days: .everyDay)
        let times = daily.upcomingHardTimes(after: Clock.night, limit: 3, calendar: Clock.calendar)
        #expect(times == [Clock.at(2026, 8, 27, 6, 40),
                          Clock.at(2026, 8, 28, 6, 40),
                          Clock.at(2026, 8, 29, 6, 40)])

        let once = AlarmSchedule(hour: 6, minute: 40)
        #expect(once.upcomingHardTimes(after: Clock.night, limit: 5, calendar: Clock.calendar).count == 1)
    }

    @Test("Day labels read like a person wrote them")
    func labels() {
        #expect(Weekdays().shortLabel == "Once")
        #expect(Weekdays.everyDay.shortLabel == "Every day")
        #expect(Weekdays.workweek.shortLabel == "Mon–Fri")
        #expect(Weekdays([.monday, .wednesday, .friday]).shortLabel == "Mon Wed Fri")
    }
}
