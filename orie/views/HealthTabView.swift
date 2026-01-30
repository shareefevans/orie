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
    let weeklyData: [DailyMacroData]
    let weeklyNote: String
    var isDark: Bool = false

    // Dot colors for macros
    private let proteinDotColor = Color(red: 49/255, green: 209/255, blue: 149/255)    // Teal green
    private let carbsDotColor = Color(red: 135/255, green: 206/255, blue: 250/255)    // Light blue
    private let fatsDotColor = Color(red: 255/255, green: 180/255, blue: 50/255)      // Yellow

    var body: some View {
        VStack(spacing: 8) {
            // MARK: - ❇️ Weekly Overview Card
            WeeklyOverviewCard(
                weekData: weeklyData,
                note: weeklyNote,
                dailyCalorieGoal: dailyCalorieGoal,
                dailyProteinGoal: dailyProteinGoal,
                dailyCarbsGoal: dailyCarbsGoal,
                dailyFatsGoal: dailyFatsGoal,
                dailySugarGoal: dailySugarGoal,
                isDark: isDark
            )

            // MARK: - ❇️ Row 1: Daily Intake (left) | Protein (right)
            HStack(spacing: 8) {
                DailyIntakeCard(
                    consumed: consumedCalories,
                    goal: dailyCalorieGoal,
                    meals: meals,
                    isDark: isDark
                )

                MacroDotCard(
                    title: "Protein",
                    consumed: consumedProtein,
                    goal: dailyProteinGoal,
                    dotColor: proteinDotColor,
                    isDark: isDark
                )
            }

            // MARK: - ❇️ Row 2: Carbs (left) | Fats (right)
            HStack(spacing: 8) {
                MacroDotCard(
                    title: "Carbs",
                    consumed: consumedCarbs,
                    goal: dailyCarbsGoal,
                    dotColor: carbsDotColor,
                    isDark: isDark
                )

                MacroDotCard(
                    title: "Fats",
                    consumed: consumedFats,
                    goal: dailyFatsGoal,
                    dotColor: fatsDotColor,
                    isDark: isDark
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
    components.weekday = 2
    let monday = calendar.date(from: components)!

    return HealthTabView(
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
        ],
        weeklyData: [
            DailyMacroData(date: monday, calories: 2200, protein: 150, carbs: 200, fats: 70, sugars: 25),
            DailyMacroData(date: calendar.date(byAdding: .day, value: 1, to: monday)!, calories: 2400, protein: 180, carbs: 220, fats: 65, sugars: 30),
            DailyMacroData(date: calendar.date(byAdding: .day, value: 2, to: monday)!, calories: 2100, protein: 140, carbs: 190, fats: 60, sugars: 20)
        ],
        weeklyNote: "Weeks looking good so far, but watch your fat levels. You've been over a few times..."
    )
    .background(Color.gray.opacity(0.1))
}
