//
//  NotificationSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct NotificationSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var themeManager: ThemeManager

    private var isDark: Bool {
        themeManager.isDarkMode
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - ❇️ Header - Notifications and unread count (centered)
                VStack(spacing: 4) {
                    Text("Notifications")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))

                    Text(notificationManager.unreadCount > 0 ? "\(notificationManager.unreadCount) unread" : "No New Notifications")
                        .font(.footnote)
                        .foregroundColor(Color.secondaryText(isDark))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)

                if notificationManager.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if !notificationManager.notifications.isEmpty {
                    // MARK: 👉 Notifications List inside a card
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVStack(spacing: 0) {
                                ForEach(notificationManager.notifications) { notification in
                                    NotificationRow(
                                        notification: notification,
                                        isDark: isDark,
                                        onTap: {
                                            notificationManager.markAsRead(notification.id)
                                        },
                                        onDelete: {
                                            notificationManager.deleteNotification(notification.id)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.cardBackground(isDark))
                        .cornerRadius(32)
                        .padding(.horizontal)
                        .padding(.top, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground(isDark))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            Task {
                await notificationManager.syncSystemNotifications()
            }
        }
    }
}

// MARK: - ❇️ Notification Row

struct NotificationRow: View {
    let notification: AppNotification
    var isDark: Bool = false
    var onTap: () -> Void
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDeleteButton = false

    private var iconName: String {
        switch notification.type {
        case .achievement:
            return "trophy.fill"
        case .update:
            return "arrow.down.circle.fill"
        case .feature:
            return "sparkles"
        case .announcement:
            return "megaphone.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case .achievement:
            return .yellow
        case .update:
            return .blue
        case .feature:
            return .purple
        case .announcement:
            return .orange
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // MARK: 👉 Delete button background
            if showDeleteButton {
                Button(action: {
                    withAnimation {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.callout)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .transition(.opacity)
            }

            // MARK: 👉 Main content
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accessibleYellow(isDark).opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconName)
                        .font(.system(size: 12))
                        .foregroundColor(Color.accessibleYellow(isDark))
                }

                // MARK: 👉 Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(notification.isRead ? .semibold : .semibold)
                            .foregroundColor(Color.primaryText(isDark))

                        Spacer()

                    }

                    Text(notification.message)
                        .font(.footnote)
                        .foregroundColor(Color.secondaryText(isDark))
                        .lineLimit(2)
                }

                // MARK: 👉 Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                        if isHorizontalDrag && value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                        withAnimation(.easeOut(duration: 0.2)) {
                            if isHorizontalDrag && value.translation.width < -50 {
                                offset = -60
                                showDeleteButton = true
                            } else {
                                offset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showDeleteButton {
                    withAnimation {
                        offset = 0
                        showDeleteButton = false
                    }
                } else {
                    onTap()
                }
            }
        }

        Divider()
            .padding(.leading, 68)
    }
}

#Preview {
    NotificationSheet()
        .environmentObject(NotificationManager())
        .environmentObject(ThemeManager())
}
