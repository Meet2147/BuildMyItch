//  RingingCoordinator.swift
//  Bridges a fired notification to the ringing screen.
//
//  Once AlarmKit is wired this shrinks: the system presents its own alert and
//  its secondary button opens the app straight into `RingingView`. Until then
//  this is what turns a tapped banner into a wake screen.

import Foundation
import UserNotifications

@Observable
public final class RingingCoordinator: NSObject {

    /// The alarm that is ringing, if one is.
    public var ringingAlarmID: UUID?

    public var isRinging: Bool { ringingAlarmID != nil }

    public func present(alarmID: UUID) { ringingAlarmID = alarmID }
    public func stop() { ringingAlarmID = nil }

    public func install() {
        UNUserNotificationCenter.current().delegate = self
    }
}

extension RingingCoordinator: UNUserNotificationCenterDelegate {

    /// An alarm arriving while you're looking at the phone still has to make a
    /// noise and take the screen.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        deliver(notification)
        completionHandler([.banner, .sound, .list])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        deliver(response.notification)
        completionHandler()
    }

    private func deliver(_ notification: UNNotification) {
        guard let raw = notification.request.content.userInfo["alarmID"] as? String,
              let identifier = UUID(uuidString: raw) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.present(alarmID: identifier)
        }
    }
}
