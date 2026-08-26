//  Alarm.swift
//  One entity. There is only ever one device writing (Aubade is iPhone-only),
//  so there is nothing to merge — but the model is still shaped for CloudKit
//  because restoring onto a new phone runs through the same machinery.

import Foundation
import SwiftData
import AubadeCore

@Model
public final class Alarm {

    public var id: UUID = UUID()
    public var label: String?

    public var hour: Int = 7
    public var minute: Int = 0
    /// How early it may ring. 0 makes it an ordinary alarm.
    public var windowMinutes: Int = 0
    public var daysRaw: Int = 0

    public var paletteRaw: String = SoundPalette.ember.rawValue
    public var rampMinutes: Int = 5
    public var lightWake: Bool = true

    public var isEnabled: Bool = true
    public var createdAt: Date = Date.distantPast
    public var modifiedAt: Date = Date.distantPast

    public init(
        id: UUID = UUID(),
        label: String? = nil,
        hour: Int = 7,
        minute: Int = 0,
        windowMinutes: Int = 0,
        days: Weekdays = [],
        palette: SoundPalette = .ember,
        rampMinutes: Int = 5,
        lightWake: Bool = true,
        isEnabled: Bool = true,
        now: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.hour = hour
        self.minute = minute
        self.windowMinutes = windowMinutes
        self.daysRaw = days.rawValue
        self.paletteRaw = palette.rawValue
        self.rampMinutes = rampMinutes
        self.lightWake = lightWake
        self.isEnabled = isEnabled
        self.createdAt = now
        self.modifiedAt = now
    }

    // MARK: - Typed accessors

    public var days: Weekdays {
        get { Weekdays(rawValue: daysRaw) }
        set { daysRaw = newValue.rawValue }
    }

    public var palette: SoundPalette {
        get { SoundPalette(rawValue: paletteRaw) ?? .ember }
        set { paletteRaw = newValue.rawValue }
    }

    public var schedule: AlarmSchedule {
        AlarmSchedule(hour: hour, minute: minute, windowMinutes: windowMinutes, days: days)
    }

    // MARK: - Presentation

    public var clockLabel: String { schedule.clockLabel }

    /// "By · 20 min window · Ember" — the line under the time.
    public var detailLabel: String {
        var parts: [String] = [days.shortLabel]
        if windowMinutes > 0 { parts.append("\(windowMinutes) min window") }
        parts.append(palette.title)
        return parts.joined(separator: " · ")
    }

    public func nextFire(after date: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        return schedule.nextHardTime(after: date, calendar: calendar)
    }

    /// "in 7h 42m" — what the night face shows.
    public func countdownLabel(from date: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let next = nextFire(after: date, calendar: calendar) else { return nil }
        let seconds = Int(next.timeIntervalSince(date))
        guard seconds > 0 else { return nil }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
