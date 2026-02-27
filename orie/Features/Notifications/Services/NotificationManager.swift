//
//  NotificationManager.swift
//  orie
//
//  Created by Shareef Evans on 21/01/2026.
//

import Foundation
import SwiftUI
import Combine

enum NotificationType: String, Codable {
    case achievement = "achievement"
    case update = "update"
    case feature = "feature"
    case announcement = "announcement"
}

struct AppNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    var isSystemNotification: Bool

    init(id: String = UUID().uuidString, type: NotificationType, title: String, message: String, timestamp: Date = Date(), isSystemNotification: Bool = false) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = false
        self.isSystemNotification = isSystemNotification
    }
}

class NotificationManager: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false

    private let notificationsKey = "appNotifications"
    private let seenSystemNotificationsKey = "seenSystemNotifications"

    init() {
        loadNotifications()
    }

    // MARK: - Sync with Backend

    @MainActor
    func syncSystemNotifications() async {
        isLoading = true

        do {
            let systemNotifications = try await NotificationService.fetchSystemNotifications()

            let seenIds = getSeenSystemNotificationIds()

            // Convert to AppNotifications and filter out already seen ones
            let newNotifications = systemNotifications
                .filter { !seenIds.contains($0.id) }
                .compactMap { sysNotif -> AppNotification? in
                    guard let type = NotificationType(rawValue: sysNotif.type),
                          let timestamp = parseISO8601(sysNotif.createdAt) else {
                        return nil
                    }

                    return AppNotification(
                        id: sysNotif.id,
                        type: type,
                        title: sysNotif.title,
                        message: sysNotif.message,
                        timestamp: timestamp,
                        isSystemNotification: true
                    )
                }

            // Add new system notifications
            for notification in newNotifications.reversed() {
                notifications.insert(notification, at: 0)
            }

            // Mark all system notifications as seen
            let allSystemIds = systemNotifications.map { $0.id }
            saveSeenSystemNotificationIds(allSystemIds)

            updateUnreadCount()
            saveNotifications()
            isLoading = false
        } catch {
            print("Failed to sync system notifications: \(error)")
            isLoading = false
        }
    }

    private func parseISO8601(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    private func getSeenSystemNotificationIds() -> Set<String> {
        if let data = UserDefaults.standard.data(forKey: seenSystemNotificationsKey),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return ids
        }
        return []
    }

    private func saveSeenSystemNotificationIds(_ ids: [String]) {
        var seenIds = getSeenSystemNotificationIds()
        ids.forEach { seenIds.insert($0) }

        if let encoded = try? JSONEncoder().encode(seenIds) {
            UserDefaults.standard.set(encoded, forKey: seenSystemNotificationsKey)
        }
    }

    // MARK: - Add Local Notifications

    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        updateUnreadCount()
        saveNotifications()
    }

    func addNotification(type: NotificationType, title: String, message: String) {
        let notification = AppNotification(type: type, title: title, message: message)
        addNotification(notification)
    }

    // MARK: - Read/Delete

    func markAsRead(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            updateUnreadCount()
            saveNotifications()
        }
    }

    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        saveNotifications()
    }

    func deleteNotification(_ notificationId: String) {
        notifications.removeAll { $0.id == notificationId }
        updateUnreadCount()
        saveNotifications()
    }

    func clearAllNotifications() {
        notifications.removeAll()
        updateUnreadCount()
        saveNotifications()
    }

    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }

    // MARK: - Persistence

    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: notificationsKey)
        }
    }

    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            notifications = decoded
            updateUnreadCount()
        }
    }

    // MARK: - Achievement Helpers

    func notifyAchievement(title: String, message: String) {
        addNotification(type: .achievement, title: title, message: message)
    }
}
