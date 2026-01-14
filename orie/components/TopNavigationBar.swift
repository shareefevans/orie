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
    @Binding var showDateSelection: Bool
    @Binding var showNotifications: Bool
    var selectedDate: Date
    var isToday: Bool
    @Binding var isInputFocused: Bool
    
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 8) {
            // Left side - Date selector
            Button(action: {
                showDateSelection = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 24)
                    Text(isToday ? "Today" : formatSelectedDate(selectedDate))
                        .font(.callout.bold())
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular.interactive())
            }
            
            Spacer()
            
            // Right side - Grouped buttons (bell, settings, trophy)
            HStack(spacing: 0) {
                
                Button(action: {
                    showAwards = true
                }) {
                    Image(systemName: "trophy")
                        .font(.callout)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                }
                
                Button(action: {
                    showNotifications = true
                }) {
                    Image(systemName: "bell")
                        .font(.callout)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                }
                
                Button(action: {
                    showProfile = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.callout)
                        .foregroundColor(.primary)
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
                        .foregroundColor(.white)
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
        showDateSelection: .constant(false),
        showNotifications: .constant(false),
        selectedDate: Date(),
        isToday: true,
        isInputFocused: .constant(false)
    )
}
