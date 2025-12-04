//
//  AwardSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct AwardSheet: View {
    @Environment(\.dismiss) var dismiss
    
    // Mock data
    @State private var currentStreak = 0
    @State private var totalBadges = 24
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header - Streak and Badges
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streak \(currentStreak) Days")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                Color(
                                    red: 69 / 255,
                                    green: 69 / 255,
                                    blue: 69 / 255
                                )
                            )
                        
                        Text("\(totalBadges) Badges Unlocked")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Badges List
                    VStack(spacing: 16) {
                        AwardRow(
                            imageName: "AwardPurpleOne",
                            title: "Deficit Devotee",
                            subtitle: "30 days under your calorie goal",
                            isUnlocked: true
                        )
                        
                        AwardRow(
                            imageName: "AwardPurpleOne",
                            title: "Macro Obsessive",
                            subtitle: "Logged protein, carbs, and fats for a week",
                            isUnlocked: true
                        )
                        
                        AwardRow(
                            imageName: "AwardGold1",
                            title: "Deficit Demon",
                            subtitle: "Hit your calorie goal for 7 days straight",
                            isUnlocked: true
                        )
                        
                        AwardRow(
                            imageName: "AwardGold2",
                            title: "Surplus Confessor",
                            subtitle: "Logged every calorie",
                            isUnlocked: true
                        )
                        
                        AwardRow(
                            imageName: "AwardGold3",
                            title: "2000 Club",
                            subtitle: "Hit your 2000 calorie target",
                            isUnlocked: true
                        )
                        
                        AwardRow(
                            imageName: "AwardSilver1",
                            title: "Calorie Cutthroat",
                            subtitle: "Maintained a 500 cal deficit for 10 days",
                            isUnlocked: false
                        )
                        
                        AwardRow(
                            imageName: "AwardSilver2",
                            title: "Maintenance Maven",
                            subtitle: "Hit maintenance calories 7 days in a row",
                            isUnlocked: false
                        )
                        
                        AwardRow(
                            imageName: "AwardSilver3",
                            title: "Weekend Warrior",
                            subtitle: "Tracked Saturday & Sunday",
                            isUnlocked: false
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
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
}
