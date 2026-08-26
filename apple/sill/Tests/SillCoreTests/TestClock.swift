//  TestClock.swift
//  A fixed Wednesday, in UTC, so every date assertion in the suite means the
//  same thing on every machine and in every CI region.

import Foundation
@testable import SillCore

enum Clock {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
        return calendar
    }()

    /// Wednesday 26 August 2026, 09:30 UTC.
    static let now = date(2026, 8, 26, 9, 30)

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.startOfDay(for: date(year, month, day))
    }
}
