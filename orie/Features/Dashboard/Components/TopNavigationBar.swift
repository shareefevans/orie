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
    @Binding var isDateSelectionMode: Bool
    @Binding var selectedDate: Date
    var isToday: Bool
    var isDark: Bool = false
    @Binding var isInputFocused: Bool
    var streakCount: Int = StreakManager.shared.currentStreak

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 8) {
            // MARK: - ❇️ Left side - Date selector and close button
            HStack(spacing: 8) {
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
                    .padding(.horizontal, 12)
                }
                .glassEffect(.regular.interactive())

                Button(action: {
                    showProfile = true
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
    TopNavigationBar(
        showAwards: .constant(false),
        showProfile: .constant(false),
        isDateSelectionMode: .constant(false),
        selectedDate: .constant(Date()),
        isToday: true,
        isDark: false,
        isInputFocused: .constant(false),
        streakCount: 20
    )
}
