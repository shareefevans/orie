//
//  TopNavigationBar.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct TopNavigationBar: View {
    @Binding var showAwards: Bool
    @Binding var showProfile: Bool
    @Binding var showSettings: Bool
    @Binding var showNotifications: Bool
    @Binding var isDateSelectionMode: Bool
    @Binding var selectedDate: Date
    @Binding var selectedTab: String
    var isToday: Bool
    var isDark: Bool = false
    @Binding var isInputFocused: Bool
    var streakCount: Int = StreakManager.shared.currentStreak
    var hasUnreadNotifications: Bool = false

    @State private var showSettingsDropdown = false
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 8) {
            // MARK: - ❇️ Left side - Back button (overview) or Date selector
            HStack(spacing: 8) {
                if selectedTab == "health" {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = "consumed"
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(width: 50, height: 50)
                            .glassEffect(.regular.interactive())
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isDateSelectionMode.toggle()
                            if isDateSelectionMode { isInputFocused = false }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(Color.iconColor(isDark))
                                .frame(width: 24)
                            if !isDateSelectionMode {
                                Text(formatDateWithToday(selectedDate, isToday: isToday))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.primaryText(isDark))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .glassEffect(.regular.interactive())
                    }

                    // MARK: 👉 X button when in date selection mode (matches keyboard dismiss button)
                    if isDateSelectionMode {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isDateSelectionMode = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.callout)
                                .foregroundColor(.black)
                                .frame(width: 50, height: 50)
                                .background(Color.accessibleYellow(isDark).opacity(0.55), in: Circle())
                                .glassEffect(in: Circle())
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity).combined(with: .scale))
                    }
                }
            }

            Spacer()

            // MARK: - ❇️ Right side - Hotstreak and settings buttons
            HStack(spacing: 8) {
                Button(action: {
                    showAwards = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.callout)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0xFE/255.0, green: 0x47/255.0, blue: 0x74/255.0),
                                        Color(red: 0xFF/255.0, green: 0xCA/255.0, blue: 0x00/255.0)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                        Text(formatCompactNumber(streakCount))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.primaryText(isDark))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 16)
                }
                .glassEffect(.regular.interactive())

                Button(action: {
                    showSettingsDropdown.toggle()
                }) {
                    Image(systemName: "ellipsis")
                        .font(.callout)
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 50, height: 50)
                }
                .glassEffect(.regular.interactive())
            }

            // MARK: 👉 Keyboard dismiss button (only shows when keyboard is open)
            if isInputFocused {
                Button(action: {
                    isInputFocused = false
                }) {
                    Image(systemName: "checkmark")
                        .font(.callout)
                        .foregroundColor(.black)
                        .frame(width: 50, height: 50)
                        .background(Color.accessibleYellow(isDark).opacity(0.55), in: Circle())
                        .glassEffect(in: Circle())
                }
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInputFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDateSelectionMode)
        .overlay(alignment: .topTrailing) {
            if showSettingsDropdown {
                settingsDropdownView
                    .padding(.top, 74)
                    .padding(.trailing, 16)
                    .transaction { $0.animation = nil }
            }
        }
    }

    private var settingsDropdownContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { showProfile = true; showSettingsDropdown = false }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 20)
                    Text("Profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Button(action: { showSettings = true; showSettingsDropdown = false }) {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 20)
                    Text("Settings")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Button(action: { showNotifications = true; showSettingsDropdown = false }) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 20)
                    Text("Notifications")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Button(action: { selectedTab = "health"; showSettingsDropdown = false }) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 20)
                    Text("Overview")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Button(action: { selectedTab = "assistance"; showSettingsDropdown = false }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 20)
                    Text("Assistance")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                    Spacer()
                }
                .padding(.top, 14)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .fixedSize()
    }

    @ViewBuilder
    private var settingsDropdownView: some View {
        if isDark {
            settingsDropdownContent
                .background(
                    Color(red: 37/255, green: 37/255, blue: 37/255),
                    in: RoundedRectangle(cornerRadius: 32, style: .continuous)
                )
        } else {
            #if os(iOS)
            settingsDropdownContent
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            #else
            settingsDropdownContent
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            #endif
        }
    }

    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }

    private func formatDateWithToday(_ date: Date, isToday: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let dateString = formatter.string(from: date)
        return isToday ? "Today, \(dateString)" : dateString
    }

    private func formatCompactNumber(_ value: Int) -> String {
        switch value {
        case 1_000_000_000...:
            let v = Double(value) / 1_000_000_000
            return v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))b" : String(format: "%.1fb", v)
        case 1_000_000...:
            let v = Double(value) / 1_000_000
            return v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))m" : String(format: "%.1fm", v)
        case 1_000...:
            let v = Double(value) / 1_000
            return v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))k" : String(format: "%.1fk", v)
        default:
            return "\(value)"
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color(red: 24/255, green: 24/255, blue: 24/255)
            .ignoresSafeArea()
        TopNavigationBar(
            showAwards: .constant(false),
            showProfile: .constant(false),
            showSettings: .constant(false),
            showNotifications: .constant(false),
            isDateSelectionMode: .constant(false),
            selectedDate: .constant(Date()),
            selectedTab: .constant("consumed"),
            isToday: true,
            isDark: true,
            isInputFocused: .constant(false),
            streakCount: 20
        )
    }
    .preferredColorScheme(.dark)
}
