import Foundation
import UserNotifications

/// Schedules the single daily training reminder. All local — no push
/// infrastructure, nothing leaves the device.
enum ReminderService {
    private static let identifier = "jawforge.daily-reminder"

    /// Call whenever the profile changes; requests permission on first use.
    static func sync(with profile: UserProfile?) {
        let center = UNUserNotificationCenter.current()
        guard let profile, profile.remindersEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            schedule(atHour: (profile.reminderTime ?? .evening).rawValue)
        }
    }

    private static func schedule(atHour hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Jawline time 💪")
        content.body = String(localized: "Your routine takes minutes. Your streak is waiting.")
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }
}
