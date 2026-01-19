//
//  HealthTabView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct HealthTabView: View {
    let consumedCalories: Int
    let dailyCalorieGoal: Int
    let burnedCalories: Int
    let consumedProtein: Int
    let dailyProteinGoal: Int
    let consumedCarbs: Int
    let dailyCarbsGoal: Int
    let consumedFats: Int
    let dailyFatsGoal: Int
    let consumedSugar: Int
    let dailySugarGoal: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Left column: Daily Intake, Sugar, Burned
            VStack(spacing: 8) {
                DailyIntakeCard(consumed: consumedCalories, goal: dailyCalorieGoal)

                SugarCard(consumed: consumedSugar)

                BurnedCard(burned: burnedCalories)
            }

            // Right column: Protein, Carbs, Fats
            VStack(spacing: 8) {
                SingleMacroCard(
                    title: "Protein",
                    consumed: consumedProtein,
                    goal: dailyProteinGoal,
                    iconName: "hexagon.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )

                SingleMacroCard(
                    title: "Carbs",
                    consumed: consumedCarbs,
                    goal: dailyCarbsGoal,
                    iconName: "square.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )

                SingleMacroCard(
                    title: "Fats",
                    consumed: consumedFats,
                    goal: dailyFatsGoal,
                    iconName: "circle.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    HealthTabView(
        consumedCalories: 1500,
        dailyCalorieGoal: 2300,
        burnedCalories: 0,
        consumedProtein: 75,
        dailyProteinGoal: 150,
        consumedCarbs: 120,
        dailyCarbsGoal: 250,
        consumedFats: 30,
        dailyFatsGoal: 65,
        consumedSugar: 0,
        dailySugarGoal: 50
    )
    .background(Color.gray.opacity(0.1))
}
