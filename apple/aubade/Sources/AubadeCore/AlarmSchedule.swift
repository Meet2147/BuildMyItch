//  AlarmSchedule.swift
//
//  You don't set 6:40. You set *by* 6:40, and a window. Aubade rings at the
//  best moment inside `[hard − window, hard]` and never, under any
//  circumstance, later than the hard time.

import Foundation

public struct AlarmSchedule: Equatable, Hashable, Codable, Sendable {

    /// The time it must not ring later than.
    public var hour: Int
    public var minute: Int
    /// How early it's allowed to ring. 0 makes it an ordinary alarm.
    public var windowMinutes: Int
    public var days: Weekdays

    public init(hour: Int, minute: Int, windowMinutes: Int = 0, days: Weekdays = []) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
        self.windowMinutes = max(0, min(60, windowMinutes))
        self.days = days
    }

    /// The next hard time strictly after `date`.
    /// Searches two weeks, which covers every repeating pattern there is.
    public func nextHardTime(after date: Date, calendar: Calendar = .current) -> Date? {
        let start = calendar.startOfDay(for: date)
        for offset in 0...14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let candidate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
            else { continue }
            guard candidate > date else { continue }
            if days.isOneShot { return candidate }
            if days.contains(calendarWeekday: calendar.component(.weekday, from: candidate)) {
                return candidate
            }
        }
        return nil
    }

    /// The earliest instant it may ring — where the ramp and the wake-window
    /// search both begin.
    public func nextWakeWindow(after date: Date, calendar: Calendar = .current) -> ClosedRange<Date>? {
        guard let hard = nextHardTime(after: date, calendar: calendar) else { return nil }
        let earliest = calendar.date(byAdding: .minute, value: -windowMinutes, to: hard) ?? hard
        return earliest...hard
    }

    /// Every hard time in the next fortnight, for the scheduler to materialise.
    /// Firing is always local: the device holds these itself and rings from
    /// them even if it never sees the network again.
    public func upcomingHardTimes(after date: Date, limit: Int = 14, calendar: Calendar = .current) -> [Date] {
        var results: [Date] = []
        var cursor = date
        while results.count < limit, let next = nextHardTime(after: cursor, calendar: calendar) {
            results.append(next)
            cursor = next
            if days.isOneShot { break }
        }
        return results
    }

    public var clockLabel: String {
        String(format: "%d:%02d", hour, minute)
    }
}
