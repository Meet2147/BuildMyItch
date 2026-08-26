//  NotificationScheduler.swift
//
//  The implementation that works today.
//
//  Time-sensitive notifications break through a Focus. They do **not** break
//  through the silent switch, and that is the whole reason AlarmKit exists.
//  Until that's wired, this is honest about what it can do rather than
//  pretending — see `capabilityNote`, which the settings screen shows word for
//  word.

import Foundation
import UserNotifications
import AubadeCore

public struct NotificationScheduler: AlarmScheduling {

    public init() {}

    // Fetched per call rather than stored: UNUserNotificationCenter is a
    // reference type and holding it would make this struct un-Sendable for no
    // benefit.
    private var center: UNUserNotificationCenter { .current() }

    public var breaksThroughSilentMode: Bool { false }

    public var capabilityNote: String {
        """
        Aubade currently rings using notifications. It will sound through a \
        Focus, and through Do Not Disturb — but not if your phone's ringer \
        switch is set to silent. Check that switch before you rely on it.
        """
    }

    public func requestAuthorization() async -> AlarmAuthorization {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted ? .limited : .denied
        } catch {
            return .denied
        }
    }

    public func schedule(_ request: AlarmRequest) async throws {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            throw AlarmSchedulingError.notAuthorized
        }

        for (index, occurrence) in request.occurrences.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = request.title
            content.body = request.palette.blurb
            // Not .defaultCritical — that needs the critical-alert entitlement,
            // which Apple grants case by case. Claiming it here without it
            // would be exactly the overstatement capabilityNote exists to avoid.
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["alarmID": request.originAlarmID.uuidString]

            var components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: occurrence
            )
            components.second = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = Self.identifier(for: request.id, index: index)
            try await center.add(UNNotificationRequest(identifier: identifier,
                                                       content: content,
                                                       trigger: trigger))
        }
    }

    public func cancel(alarmID: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let mine = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.prefix(for: alarmID)) }
        center.removePendingNotificationRequests(withIdentifiers: mine)
    }

    public func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    // Occurrences are materialised one notification each — iOS caps pending
    // requests at 64 per app, which is why the store asks for a fortnight
    // rather than a year, and re-runs the loop on every launch.
    private static func prefix(for id: UUID) -> String { "aubade.\(id.uuidString)." }
    private static func identifier(for id: UUID, index: Int) -> String { prefix(for: id) + String(index) }
}
