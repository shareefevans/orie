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
    let sugarConsumed: Int
    let sugarGoal: Int

    var body: some View {
        VStack(spacing: 8) {
            // First row: Protein & Fats
            HStack(spacing: 8) {
                SingleMacroCard(
                    title: "Protein",
                    consumed: proteinConsumed,
                    goal: proteinGoal,
                    iconName: "triangle.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )

                SingleMacroCard(
                    title: "Fats",
                    consumed: fatsConsumed,
                    goal: fatsGoal,
                    iconName: "circle.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )
            }

            // Second row: Carbs & Sugar
            HStack(spacing: 8) {
                SingleMacroCard(
                    title: "Carbs",
                    consumed: carbsConsumed,
                    goal: carbsGoal,
                    iconName: "square.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )

                SugarCard(consumed: sugarConsumed)
            }
        }
    }
}

struct SingleMacroCard: View {
    let title: String
    let consumed: Int
    let goal: Int
    let iconName: String
    let iconColor: Color
    let gradientColors: [Color]

    private var remaining: Int {
        goal - consumed
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Text("g")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .fontWeight(.regular)
            }
            .padding(.top, 4)

            Text("\(remaining)g left")
                .font(.system(size: 12))
                .foregroundColor(remaining > 0 ? .yellow : .red)
                .padding(.top, 4)
                .padding(.bottom, 24)

            Spacer()

            // Pie chart with icon and goal
            HStack(alignment: .bottom) {
                ZStack {
                    CircularProgressChart(
                        progress: progress,
                        size: 40,
                        lineWidth: 5,
                        gradientColors: gradientColors
                    )

                    // Centered icon with light background circle
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 22, height: 22)

                    Image(systemName: iconName)
                        .font(.system(size: 10))
                        .foregroundColor(iconColor)
                }

                Spacer()

                Text("\(goal)g")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(32)
    }
}

struct SugarCard: View {
    let consumed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sugar")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.red)

                Text("grams")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .fontWeight(.regular)
            }
            .padding(.top, 4)

            Spacer()

            // Heart icon in bottom left (like BurnedCard)
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(32)
    }
}

#Preview {
    MacrosCard(
        proteinConsumed: 75,
        proteinGoal: 150,
        fatsConsumed: 30,
        fatsGoal: 65,
        carbsConsumed: 120,
        carbsGoal: 250,
        sugarConsumed: 0,
        sugarGoal: 50
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
