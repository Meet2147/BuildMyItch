//  AlarmStore.swift
//  Every change to an alarm goes through here, and every change re-runs the
//  reconciliation loop. Scheduling is idempotent and cheap, so it's safe to
//  run it constantly — which means it does, and the OS never drifts from the
//  model.

import Foundation
import SwiftData
import AubadeCore

@Observable
public final class AlarmStore {

    private let context: ModelContext
    private let scheduler: any AlarmScheduling
    private let calendar: Calendar

    public private(set) var authorization: AlarmAuthorization = .unknown

    /// Passed straight through from whichever scheduler is installed, and
    /// shown verbatim in the app. When AlarmKit lands, this sentence changes
    /// on its own — which is the point of putting it behind the protocol.
    public var capabilityNote: String { scheduler.capabilityNote }
    public var breaksThroughSilentMode: Bool { scheduler.breaksThroughSilentMode }

    public init(context: ModelContext, scheduler: any AlarmScheduling, calendar: Calendar = .current) {
        self.context = context
        self.scheduler = scheduler
        self.calendar = calendar
    }

    // MARK: - Authorization

    public func requestAuthorization() async {
        authorization = await scheduler.requestAuthorization()
    }

    // MARK: - Editing

    @discardableResult
    public func add(hour: Int, minute: Int, days: Weekdays = [], now: Date = Date()) -> Alarm {
        let alarm = Alarm(hour: hour, minute: minute, days: days, now: now)
        context.insert(alarm)
        return alarm
    }

    public func setEnabled(_ enabled: Bool, on alarm: Alarm, now: Date = Date()) async {
        alarm.isEnabled = enabled
        alarm.modifiedAt = now
        await reconcile(alarm, now: now)
    }

    public func update(_ alarm: Alarm, now: Date = Date(), _ change: (Alarm) -> Void) async {
        change(alarm)
        alarm.modifiedAt = now
        await reconcile(alarm, now: now)
    }

    public func delete(_ alarm: Alarm) async {
        await scheduler.cancel(alarmID: alarm.id)
        context.delete(alarm)
    }

    // MARK: - Snooze

    /// A snooze is its own one-off request under its own id, so re-running the
    /// reconciliation loop can't wipe it and cancelling it can't wipe the
    /// repeating alarm.
    private var snoozeIDs: [UUID: UUID] = [:]

    public func snooze(_ alarm: Alarm, minutes: Int, now: Date = Date()) async {
        await cancelSnooze(for: alarm)
        let requestID = UUID()
        snoozeIDs[alarm.id] = requestID
        let fireAt = calendar.date(byAdding: .minute, value: minutes, to: now) ?? now
        try? await scheduler.schedule(
            AlarmRequest(
                id: requestID,
                originAlarmID: alarm.id,
                title: alarm.label ?? "Alarm",
                occurrences: [fireAt],
                palette: alarm.palette,
                repeats: false
            )
        )
    }

    public func cancelSnooze(for alarm: Alarm) async {
        guard let requestID = snoozeIDs.removeValue(forKey: alarm.id) else { return }
        await scheduler.cancel(alarmID: requestID)
    }

    // MARK: - Reconciliation
    //
    // Read the model, diff it against what the OS is currently holding, and
    // make the OS match. Never the other way round: the model is the truth.

    public func reconcile(_ alarm: Alarm, now: Date = Date()) async {
        await scheduler.cancel(alarmID: alarm.id)
        guard alarm.isEnabled else { return }
        let occurrences = alarm.schedule.upcomingHardTimes(after: now, limit: 14, calendar: calendar)
        try? await scheduler.schedule(
            AlarmRequest(
                id: alarm.id,
                originAlarmID: alarm.id,
                title: alarm.label ?? "Alarm",
                occurrences: occurrences,
                palette: alarm.palette,
                repeats: !alarm.days.isOneShot
            )
        )
    }

    public func reconcileAll(_ alarms: [Alarm], now: Date = Date()) async {
        for alarm in alarms {
            await reconcile(alarm, now: now)
        }
    }
}
