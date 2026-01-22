//
//  AwardSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct AwardSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    private var isDark: Bool { themeManager.isDarkMode }

    // Mock data
    @State private var currentStreak = 0
    @State private var totalBadges = 24

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header - Streak and Badges
                    VStack(spacing: 4) {
                        Text("\(currentStreak) Days")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primaryText(isDark))

                        Text("\(totalBadges) Badges Unlocked")
                            .font(.footnote)
                            .foregroundColor(Color.secondaryText(isDark))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 32)
                    .padding(.bottom, 8)
                    
                    // Badges List
                    VStack(spacing: 16) {
                        AwardRow(
                            imageName: "AwardPurpleOne",
                            title: "Deficit Devotee",
                            subtitle: "30 days under your calorie goal",
                            isUnlocked: true,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardPurpleOne",
                            title: "Macro Obsessive",
                            subtitle: "Logged protein, carbs, and fats for a week",
                            isUnlocked: true,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardGold1",
                            title: "Deficit Demon",
                            subtitle: "Hit your calorie goal for 7 days straight",
                            isUnlocked: true,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardGold2",
                            title: "Surplus Confessor",
                            subtitle: "Logged every calorie",
                            isUnlocked: true,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardGold3",
                            title: "2000 Club",
                            subtitle: "Hit your 2000 calorie target",
                            isUnlocked: true,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardSilver1",
                            title: "Calorie Cutthroat",
                            subtitle: "Maintained a 500 cal deficit for 10 days",
                            isUnlocked: false,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardSilver2",
                            title: "Maintenance Maven",
                            subtitle: "Hit maintenance calories 7 days in a row",
                            isUnlocked: false,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardSilver3",
                            title: "Weekend Warrior",
                            subtitle: "Tracked Saturday & Sunday",
                            isUnlocked: false,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardBronze1",
                            title: "Calorie Cutthroat",
                            subtitle: "Maintained a 500 cal deficit for 10 days",
                            isUnlocked: false,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardBronze2",
                            title: "Maintenance Maven",
                            subtitle: "Hit maintenance calories 7 days in a row",
                            isUnlocked: false,
                            isDark: isDark
                        )
                        
                        AwardRow(
                            imageName: "AwardBronze3",
                            title: "Weekend Warrior",
                            subtitle: "Tracked Saturday & Sunday",
                            isUnlocked: false,
                            isDark: isDark
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
    }
}

// Award Row Component
struct AwardRow: View {
    let imageName: String
    let title: String
    let subtitle: String
    let isUnlocked: Bool
    let isDark: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Badge Image
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .opacity(isUnlocked ? 1.0 : 0.25)

            // Title and Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText(isDark))

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.secondaryText(isDark))
            }

            Spacer()

            // Status Indicator
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    AwardSheet()
        .environmentObject(ThemeManager())
}
