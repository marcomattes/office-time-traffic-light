import Foundation
import UserNotifications

enum Notifications {
    static func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    /// The one-time notification when the daily goal is reached.
    static func dailyGoalReached(officeTime: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Daily goal reached"
        content.body = "Office time today: \(officeTime.hoursMinutes)"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "dailyGoal", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

/// Shows the notification even while the app's menu is open.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
