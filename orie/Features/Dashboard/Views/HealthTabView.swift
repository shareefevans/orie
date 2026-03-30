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
    let consumedFibre: Int
    let dailyFibreGoal: Int
    let consumedSodium: Int
    let dailySodiumGoal: Int
    let consumedSugar: Int
    let dailySugarGoal: Int
    let meals: [MealBubble]
    let weeklyData: [DailyMacroData]
    let weeklyNote: String
    var isDark: Bool = false

    // Dot colors for macros
    private let proteinDotColor = Color(red: 49/255, green: 209/255, blue: 149/255)    // Teal green
    private let carbsDotColor = Color(red: 135/255, green: 206/255, blue: 250/255)     // Light blue
    private let fatsDotColor = Color(red: 255/255, green: 180/255, blue: 50/255)       // Yellow
    // Dot colors for nutrients
    private let fibreDotColor = Color(red: 160/255, green: 80/255, blue: 255/255)      // Purple
    private let sodiumDotColor = Color(red: 255/255, green: 105/255, blue: 180/255)    // Pink
    private let sugarDotColor = Color(red: 255/255, green: 30/255, blue: 60/255)       // Candy red

    private var activeDays: [DailyMacroData] { weeklyData.filter { $0.calories > 0 } }

    private var weeklyAvgCalories: Int {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0) { $0 + $1.calories } / activeDays.count
    }
    private var weeklyAvgProtein: Int {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0) { $0 + $1.protein } / activeDays.count
    }
    private var weeklyAvgCarbs: Int {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0) { $0 + $1.carbs } / activeDays.count
    }
    private var weeklyAvgFats: Int {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0) { $0 + $1.fats } / activeDays.count
    }
    private var weeklyAvgFibre: Int {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0) { $0 + $1.fibre } / activeDays.count
    }
    private var weeklyAvgSodium: Int {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0) { $0 + $1.sodium } / activeDays.count
    }
    private var weeklyAvgSugar: Int {
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0) { $0 + $1.sugar } / activeDays.count
    }

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
                dailyFibreGoal: dailyFibreGoal,
                dailySodiumGoal: dailySodiumGoal,
                dailySugarGoal: dailySugarGoal,
                isDark: isDark
            )

            // MARK: - ❇️ Row 1: Daily Intake (left) | Protein (right)
            HStack(spacing: 8) {
                DailyIntakeCard(
                    consumed: weeklyAvgCalories,
                    goal: dailyCalorieGoal,
                    meals: [],
                    isDark: isDark,
                    daysLogged: activeDays.count
                )

                MacroDotCard(
                    title: "Protein Avg.",
                    consumed: weeklyAvgProtein,
                    goal: dailyProteinGoal,
                    dotColor: proteinDotColor,
                    isDark: isDark,
                    daysLogged: activeDays.count
                )
            }

            // MARK: - ❇️ Row 2: Carbs (left) | Fats (right)
            HStack(spacing: 8) {
                MacroDotCard(
                    title: "Carbs Avg.",
                    consumed: weeklyAvgCarbs,
                    goal: dailyCarbsGoal,
                    dotColor: carbsDotColor,
                    isDark: isDark,
                    daysLogged: activeDays.count
                )

                MacroDotCard(
                    title: "Fats Avg.",
                    consumed: weeklyAvgFats,
                    goal: dailyFatsGoal,
                    dotColor: fatsDotColor,
                    isDark: isDark,
                    daysLogged: activeDays.count
                )
            }

            // MARK: - ❇️ Row 3: Fibre (left) | Sodium (right)
            HStack(spacing: 8) {
                NutrientDotCard(
                    title: "Fibre Avg.",
                    consumed: weeklyAvgFibre,
                    unit: "g",
                    displayUnit: "grams",
                    dotColor: fibreDotColor,
                    goal: dailyFibreGoal,
                    isDark: isDark
                )

                NutrientDotCard(
                    title: "Sodium Avg.",
                    consumed: weeklyAvgSodium,
                    unit: "mg",
                    dotColor: sodiumDotColor,
                    goal: dailySodiumGoal,
                    isDark: isDark,
                    daysLogged: activeDays.count,
                    heavyOverOnly: true
                )
            }

            // MARK: - ❇️ Row 4: Sugar (full width)
            NutrientDotCard(
                title: "Sugar Avg.",
                consumed: weeklyAvgSugar,
                unit: "g",
                displayUnit: "grams",
                dotColor: sugarDotColor,
                goal: dailySugarGoal,
                isDark: isDark,
                daysLogged: activeDays.count,
                heavyOverOnly: true
            )
        }
        .padding(.top, 24)
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
        consumedFibre: 22,
        dailyFibreGoal: 30,
        consumedSodium: 1200,
        dailySodiumGoal: 2300,
        consumedSugar: 35,
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
            DailyMacroData(date: monday, calories: 2200, protein: 150, carbs: 200, fats: 70, fibre: 28, sodium: 1800, sugar: 45),
            DailyMacroData(date: calendar.date(byAdding: .day, value: 1, to: monday)!, calories: 2400, protein: 180, carbs: 220, fats: 65, fibre: 32, sodium: 2100, sugar: 38),
            DailyMacroData(date: calendar.date(byAdding: .day, value: 2, to: monday)!, calories: 2100, protein: 140, carbs: 190, fats: 60, fibre: 25, sodium: 1600, sugar: 50)
        ],
        weeklyNote: "Weeks looking good so far, but watch your fat levels. You've been over a few times..."
    )
    .background(Color.gray.opacity(0.1))
}
