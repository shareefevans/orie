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
    var selectedDate: Date
    var isToday: Bool
    
    var body: some View {
        ZStack {
            // Left side
            HStack {
                // 🏆 Trophy button (left)
                Button(action: {
                    showAwards = true
                }) {
                    Image(systemName: "trophy")
                        .font(.callout)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .glassEffect(.regular.interactive())
                }
                
                Spacer()
            }
            
            // Center - App icon + Date selector (perfectly centered)
            Button(action: {
                showDateSelection = true
            }) {
                HStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 50)
                    Text(isToday ? "Today" : formatSelectedDate(selectedDate))
                        .font(.callout.bold())
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 0)
                .glassEffect(.regular.interactive())
            }
            
            // Right side
            HStack {
                Spacer()
                
                // 🔔 Right side - Bell and Settings (grouped in one glass frame)
                HStack(spacing: 0) {
                    Button(action: {
                        // Notifications action
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
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
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
        selectedDate: Date(),
        isToday: true
    )
}
