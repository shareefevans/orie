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
    @Binding var showNotifications: Bool
    @Binding var isDateSelectionMode: Bool
    @Binding var selectedDate: Date
    var isToday: Bool
    var isDark: Bool = false
    @Binding var isInputFocused: Bool
    var hasUnreadNotifications: Bool = false

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 8) {
            // Left side - Date selector and close button
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isDateSelectionMode.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 20))
                            .foregroundColor(Color.iconColor(isDark))
                            .frame(width: 24)
                        if !isDateSelectionMode {
                            Text(isToday ? "Today" : formatSelectedDate(selectedDate))
                                .font(.callout.bold())
                                .foregroundColor(Color.primaryText(isDark))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassEffect(.regular.interactive())
                }

                // X button when in date selection mode (matches keyboard dismiss button)
                if isDateSelectionMode {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isDateSelectionMode = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.callout)
                            .foregroundColor(isDark ? .black : .white)
                            .frame(width: 50, height: 50)
                            .background(Color.yellow)
                            .clipShape(Circle())
                            .glassEffect(.regular.interactive())
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity).combined(with: .scale))
                }
            }

            Spacer()

            // Right side - Grouped buttons (bell, settings, trophy)
            HStack(spacing: 0) {

                Button(action: {
                    showAwards = true
                }) {
                    Image(systemName: "trophy")
                        .font(.callout)
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 50, height: 50)
                }

                Button(action: {
                    showNotifications = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.callout)
                            .foregroundColor(Color.iconColor(isDark))
                            .frame(width: 50, height: 50)

                        if hasUnreadNotifications {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: -14, y: 14)
                        }
                    }
                }

                Button(action: {
                    showProfile = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.callout)
                        .foregroundColor(Color.iconColor(isDark))
                        .frame(width: 44, height: 44)
                }

            }
            .glassEffect(.regular.interactive())

            // Keyboard dismiss button (only shows when keyboard is open)
            if isInputFocused {
                Button(action: {
                    isInputFocused = false
                }) {
                    Image(systemName: "checkmark")
                        .font(.callout)
                        .foregroundColor(isDark ? .black : .white)
                        .frame(width: 50, height: 50)
                        .background(Color.yellow)
                        .clipShape(Circle())
                        .glassEffect(.regular.interactive())
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
}

#Preview {
    TopNavigationBar(
        showAwards: .constant(false),
        showProfile: .constant(false),
        showNotifications: .constant(false),
        isDateSelectionMode: .constant(false),
        selectedDate: .constant(Date()),
        isToday: true,
        isDark: false,
        isInputFocused: .constant(false),
        hasUnreadNotifications: true
    )
}
