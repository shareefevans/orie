//
//  MacrosCard.swift
//  orie
//
//  Created by Shareef Evans on 19/01/2026.
//

import SwiftUI

struct MacrosCard: View {
    let proteinConsumed: Int
    let proteinGoal: Int
    let fatsConsumed: Int
    let fatsGoal: Int
    let carbsConsumed: Int
    let carbsGoal: Int

    var body: some View {
        HStack(spacing: 0) {
            // Protein (left)
            MacroItem(
                title: "Protein",
                consumed: proteinConsumed,
                goal: proteinGoal,
                iconName: "fish.fill",
                iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                gradientColors: [
                    Color(red: 75/255, green: 78/255, blue: 255/255),
                    Color(red: 106/255, green: 118/255, blue: 255/255)
                ]
            )

            Spacer()

            // Fats (middle)
            MacroItem(
                title: "Fats",
                consumed: fatsConsumed,
                goal: fatsGoal,
                iconName: "drop.fill",
                iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                gradientColors: [
                    Color(red: 75/255, green: 78/255, blue: 255/255),
                    Color(red: 106/255, green: 118/255, blue: 255/255)
                ]
            )

            Spacer()

            // Carbs (right)
            MacroItem(
                title: "Carbs",
                consumed: carbsConsumed,
                goal: carbsGoal,
                iconName: "tree.fill",
                iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                gradientColors: [
                    Color(red: 75/255, green: 78/255, blue: 255/255),
                    Color(red: 106/255, green: 118/255, blue: 255/255)
                ]
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(32)
    }
}

struct MacroItem: View {
    let title: String
    let consumed: Int
    let goal: Int
    let iconName: String
    let iconColor: Color
    let gradientColors: [Color]

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pie chart with centered icon
            ZStack {
                CircularProgressChart(
                    progress: progress,
                    size: 56,
                    lineWidth: 6,
                    gradientColors: gradientColors
                )

                // Centered icon with light background circle
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
            }

            // Macro type label
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fontWeight(.medium)
                .padding(.top, 16)
                .padding(.bottom, 4)

            // Consumed / Goal
            Text("\(consumed) / \(goal)g")
                .font(.system(size: 12))
                .foregroundColor(.black)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MacrosCard(
        proteinConsumed: 75,
        proteinGoal: 150,
        fatsConsumed: 30,
        fatsGoal: 65,
        carbsConsumed: 120,
        carbsGoal: 250
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
