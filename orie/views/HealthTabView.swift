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

    var body: some View {
        VStack(spacing: 0) {
            // Daily Intake & Burned Cards (side by side)
            HStack(spacing: 8) {
                DailyIntakeCard(consumed: consumedCalories, goal: dailyCalorieGoal)
                BurnedCard(burned: burnedCalories)
            }
            .padding(.horizontal, 16)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            // Protein Card (full width)
            ProteinCard(consumed: consumedProtein, goal: dailyProteinGoal)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            // Carbs & Fats Cards (side by side)
            HStack(spacing: 8) {
                MacroCircularCard(
                    title: "Carbohydrates",
                    consumed: consumedCarbs,
                    goal: dailyCarbsGoal,
                    unit: "grams"
                )
                MacroCircularCard(
                    title: "Fats",
                    consumed: consumedFats,
                    goal: dailyFatsGoal,
                    unit: "grams"
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
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
        dailyFatsGoal: 65
    )
    .background(Color.gray.opacity(0.1))
}
