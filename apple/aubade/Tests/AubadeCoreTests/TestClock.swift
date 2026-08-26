//  TestClock.swift
//  A fixed Wednesday night in UTC, so alarm arithmetic means the same thing
//  on every machine and in every CI region.

import Foundation
@testable import AubadeCore

enum Clock {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
        return calendar
    }()

    /// Wednesday 26 August 2026, 22:30 UTC — bedtime, before a morning alarm.
    static let night = at(2026, 8, 26, 22, 30)

    static func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Clock.calendar.date(from: components)!
    }
}
