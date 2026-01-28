import Foundation
import UserNotifications
import Combine

class LocalNotificationManager: ObservableObject {
    static let shared = LocalNotificationManager()

    @Published var isAuthorized = false
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "mealNotificationsEnabled")
            if !notificationsEnabled {
                cancelAllMealNotifications()
            }
        }
    }

    private init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "mealNotificationsEnabled")
        Task { @MainActor in
            await checkAuthorizationStatus()
        }
    }

    // MARK: ❇️ - Authorization

    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            self.isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    @MainActor
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - ❇️ Schedule Notifications

    /// Schedule a notification for a food entry at its timestamp
    func scheduleMealNotification(for entry: FoodEntry) {
        print("📅 Attempting to schedule notification for: \(entry.foodName)")
        print("   - notificationsEnabled: \(notificationsEnabled)")
        print("   - isAuthorized: \(isAuthorized)")
        print("   - entry time: \(entry.timestamp)")
        print("   - is future: \(entry.timestamp > Date())")

        guard notificationsEnabled && isAuthorized else {
            print("❌ Notifications not enabled or not authorized")
            return
        }

        // 👉 Don't schedule if the time has already passed
        guard entry.timestamp > Date() else {
            print("❌ Time is in the past, skipping")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Que Pasa Puto!"
        content.body = "Time to eat: \(entry.foodName)"
        content.sound = .default
        content.userInfo = ["entryId": entry.id.uuidString]

        // 👉 Create trigger based on the entry's timestamp
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: entry.timestamp
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // 👉 Use entry ID as notification identifier for easy management
        let request = UNNotificationRequest(
            identifier: "meal-\(entry.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Scheduled notification for \(entry.foodName) at \(entry.timestamp)")
            }
        }
    }

    /// Update notification when entry time changes
    func updateMealNotification(for entry: FoodEntry) {
        print("🔄 Updating notification for: \(entry.foodName) to time: \(entry.timestamp)")
        cancelMealNotification(for: entry.id)
        scheduleMealNotification(for: entry)
    }

    /// Cancel notification for a specific entry
    func cancelMealNotification(for entryId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["meal-\(entryId.uuidString)"]
        )
    }

    /// Cancel all meal notifications
    func cancelAllMealNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let mealIds = requests
                .filter { $0.identifier.hasPrefix("meal-") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: mealIds)
        }
    }

    /// Reschedule all notifications for entries (useful after app restart)
    func rescheduleAllNotifications(for entries: [FoodEntry]) {
        guard notificationsEnabled && isAuthorized else { return }

        // 👉 Cancel existing and reschedule
        cancelAllMealNotifications()

        for entry in entries where entry.timestamp > Date() {
            scheduleMealNotification(for: entry)
        }
    }
}
