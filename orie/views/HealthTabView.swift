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
    let meals: [MealBubble]

    // Dot colors for macros
    private let proteinDotColor = Color(red: 55/255, green: 48/255, blue: 163/255)    // Dark blue
    private let carbsDotColor = Color(red: 135/255, green: 206/255, blue: 250/255)    // Light blue
    private let fatsDotColor = Color(red: 255/255, green: 180/255, blue: 50/255)      // Yellow

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: Daily Intake (full width)
            DailyIntakeCard(
                consumed: consumedCalories,
                goal: dailyCalorieGoal,
                meals: meals
            )

            // Row 2: Protein (left) | Carbs (right)
            HStack(spacing: 8) {
                MacroDotCard(
                    title: "Protein",
                    consumed: consumedProtein,
                    goal: dailyProteinGoal,
                    dotColor: proteinDotColor
                )

                MacroDotCard(
                    title: "Carbs",
                    consumed: consumedCarbs,
                    goal: dailyCarbsGoal,
                    dotColor: carbsDotColor
                )
            }

            // Row 3: Fats (left) | Burned + Sugar stacked (right)
            HStack(spacing: 8) {
                MacroDotCard(
                    title: "Fats",
                    consumed: consumedFats,
                    goal: dailyFatsGoal,
                    dotColor: fatsDotColor
                )

                // Burned and Sugar stacked vertically
                VStack(spacing: 8) {
                    BurnedMiniCard(burned: burnedCalories)
                    SugarMiniCard(consumed: consumedSugar)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
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
        dailySugarGoal: 50,
        meals: [
            MealBubble(
                timestamp: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
                protein: 20,
                carbs: 35,
                fats: 15
            ),
            MealBubble(
                timestamp: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!,
                protein: 35,
                carbs: 25,
                fats: 18
            )
        ]
    )
    .background(Color.gray.opacity(0.1))
}
