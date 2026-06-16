import Foundation
import UserNotifications

/// Handles local notifications for fish events
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var authorizationGranted: Bool = false

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    /// Request notification permissions
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.authorizationGranted = granted
            }
            if let error = error {
                print("Notification auth error: \(error)")
            }
        }
    }

    // MARK: - Scheduling

    /// Schedule a notification at a specific date
    func scheduleNotification(title: String, body: String, identifier: String, date: Date? = nil) {
        guard authorizationGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger: UNNotificationTrigger
        if let date = date {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            // Immediate with slight delay
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }

    /// Cancel a specific notification
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all pending notifications
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Convenience methods

    /// Schedule the "lonely fish" reminder (fires if no interaction in 4 hours)
    func scheduleLonelyReminder(fishName: String, fishID: UUID) {
        scheduleNotification(
            title: "\(fishName) is lonely! 🐠",
            body: "Your fish hasn't been fed in a while. Tap to feed!",
            identifier: "lonely-\(fishID)",
            date: Date().addingTimeInterval(4 * 3600)
        )
    }

    /// Schedule hatching notification
    func scheduleHatchingNotification(fishName: String, pairID: UUID, hatchDate: Date) {
        scheduleNotification(
            title: "Eggs are hatching! 🥚",
            body: "\(fishName)'s eggs are ready! Check the hatchery.",
            identifier: "hatch-\(pairID)",
            date: hatchDate
        )
    }

    /// Schedule growth notification
    func scheduleGrowthNotification(fishName: String, fishID: UUID) {
        scheduleNotification(
            title: "Your fish grew! 📏",
            body: "\(fishName) reached a new size!",
            identifier: "growth-\(fishID)"
        )
    }
}
