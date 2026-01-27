//
//  MealProgressBar.swift
//  orie
//
//  Created by Shareef Evans on 20/01/2026.
//

import SwiftUI

struct MealBubble: Identifiable {
    let id = UUID()
    let timestamp: Date
    let protein: Double
    let carbs: Double
    let fats: Double

    var totalMacros: Double {
        protein + carbs + fats
    }
}

struct MealProgressBar: View {
    let progress: Double
    let meals: [MealBubble]
    var height: CGFloat = 6
    var isDark: Bool = false
    var animationDuration: Double = 0.8
    var animationDelay: Double = 0

    // MARK: 👉Macro colors
    private let proteinColor = Color(red: 55/255, green: 48/255, blue: 163/255)    // Dark blue
    private let carbsColor = Color(red: 135/255, green: 206/255, blue: 250/255)    // Light blue
    private let fatsColor = Color(red: 255/255, green: 180/255, blue: 50/255)      // Orange/Yellow

    // MARK: 👉Time between meals color (purple-blue)
    private let timeColor = Color(red: 106/255, green: 118/255, blue: 255/255)

    // MARK: 👉Unfilled color
    private var unfilledColor: Color {
        Color.chartBackground(isDark)
    }

    @State private var animatedProgress: Double = 0

    // MARK: - ❇️ Body
    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let sortedMeals = meals.sorted { $0.timestamp < $1.timestamp }
            let pills = buildPills(sortedMeals: sortedMeals)

            // MARK: 👉Calculate where the filled portion ends
            let filledWidth = barWidth * CGFloat(animatedProgress)
            let unfilledWidth = barWidth - filledWidth

            ZStack(alignment: .leading) {
                // MARK: 👉Colored pills (filled portion)
                HStack(spacing: 0) {
                    ForEach(Array(pills.enumerated()), id: \.offset) { index, pill in
                        let pillWidth = barWidth * pill.widthFraction

                        ColoredPillView(
                            pill: pill,
                            width: pillWidth,
                            height: height,
                            proteinColor: proteinColor,
                            carbsColor: carbsColor,
                            fatsColor: fatsColor,
                            timeColor: timeColor,
                            overallProgress: animatedProgress,
                            pillStartProgress: calculatePillStartProgress(pills: pills, index: index),
                            pillEndProgress: calculatePillEndProgress(pills: pills, index: index)
                        )
                    }
                }

                // MARK: 👉Grey unfilled portion (starts where progress ends)
                if unfilledWidth > 0 && animatedProgress < 1.0 {
                    Capsule()
                        .fill(unfilledColor)
                        .frame(width: unfilledWidth, height: height)
                        .offset(x: filledWidth)
                }
            }
        }
        .frame(height: height)
        .onAppear {
            animatedProgress = 0
            withAnimation(.easeOut(duration: animationDuration).delay(animationDelay)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: animationDuration)) {
                animatedProgress = newValue
            }
        }
    }

    // MARK: - ❇️ Functions
    private func buildPills(sortedMeals: [MealBubble]) -> [PillData] {
        var pills: [PillData] = []

        if sortedMeals.isEmpty {
            // MARK: 👉No meals - single time pill
            pills.append(PillData(type: .time, widthFraction: 1.0))
            return pills
        }

        // MARK: 👉Calculate total macros for proportional meal sizing
        let totalAllMacros = sortedMeals.reduce(0.0) { $0 + $1.totalMacros }
        let mealCount = sortedMeals.count

        // MARK: 👉Calculate time gaps between meals
        var timeGaps: [TimeInterval] = []
        let calendar = Calendar.current

        // MARK: 👉First gap: from start of day (6am) to first meal
        let startOfDay = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: sortedMeals[0].timestamp) ?? sortedMeals[0].timestamp
        let firstGap = max(0, sortedMeals[0].timestamp.timeIntervalSince(startOfDay))
        timeGaps.append(firstGap)

        // MARK: 👉Gaps between consecutive meals
        for i in 1..<sortedMeals.count {
            let gap = sortedMeals[i].timestamp.timeIntervalSince(sortedMeals[i-1].timestamp)
            timeGaps.append(max(0, gap))
        }

        let totalTimeGap = timeGaps.reduce(0, +)

        // MARK: 👉Distribution: 40% for time segments, 60% for meals
        let timeTotalFraction: CGFloat = 0.4
        let mealsTotalFraction: CGFloat = 0.6

        for (index, meal) in sortedMeals.enumerated() {
            // MARK: 👉Time pill before each meal - width proportional to time gap
            let timeGap = timeGaps[index]
            let timeFraction = totalTimeGap > 0
                ? timeTotalFraction * CGFloat(timeGap / totalTimeGap)
                : timeTotalFraction / CGFloat(mealCount)
            pills.append(PillData(type: .time, widthFraction: timeFraction))

            // MARK: 👉Meal's share of total meal space
            let mealFraction = totalAllMacros > 0
                ? mealsTotalFraction * (meal.totalMacros / totalAllMacros)
                : mealsTotalFraction / CGFloat(mealCount)

            // MARK: 👉Add macro pills in order: fats, protein, carbs
            if meal.fats > 0 {
                let fatFraction = mealFraction * (meal.fats / meal.totalMacros)
                pills.append(PillData(type: .fats, widthFraction: fatFraction))
            }
            if meal.protein > 0 {
                let proteinFraction = mealFraction * (meal.protein / meal.totalMacros)
                pills.append(PillData(type: .protein, widthFraction: proteinFraction))
            }
            if meal.carbs > 0 {
                let carbsFraction = mealFraction * (meal.carbs / meal.totalMacros)
                pills.append(PillData(type: .carbs, widthFraction: carbsFraction))
            }
        }

        return pills
    }

    private func calculatePillStartProgress(pills: [PillData], index: Int) -> Double {
        var cumulative: Double = 0
        for i in 0..<index {
            cumulative += pills[i].widthFraction
        }
        return cumulative
    }

    private func calculatePillEndProgress(pills: [PillData], index: Int) -> Double {
        var cumulative: Double = 0
        for i in 0...index {
            cumulative += pills[i].widthFraction
        }
        return cumulative
    }
}

struct PillData {
    enum PillType {
        case time
        case protein
        case carbs
        case fats
    }

    let type: PillType
    let widthFraction: CGFloat
}

struct ColoredPillView: View {
    let pill: PillData
    let width: CGFloat
    let height: CGFloat
    let proteinColor: Color
    let carbsColor: Color
    let fatsColor: Color
    let timeColor: Color
    let overallProgress: Double
    let pillStartProgress: Double
    let pillEndProgress: Double

    private var fillColor: Color {
        switch pill.type {
        case .time:
            return timeColor
        case .protein:
            return proteinColor
        case .carbs:
            return carbsColor
        case .fats:
            return fatsColor
        }
    }

    // MARK: 👉 Calculate how much of this pill should be filled (0 to 1)
    private var fillFraction: CGFloat {
        if overallProgress >= pillEndProgress {
            return 1.0
        } else if overallProgress <= pillStartProgress {
            return 0.0
        } else {
            let pillRange = pillEndProgress - pillStartProgress
            let progressInPill = overallProgress - pillStartProgress
            return CGFloat(progressInPill / pillRange)
        }
    }

    var body: some View {
        // MARK: 👉Only show the colored pill if there's any fill
        if fillFraction > 0 {
            Capsule()
                .fill(fillColor)
                .frame(width: width * fillFraction, height: height)
                .frame(width: width, alignment: .leading)
        } else {
            // Empty spacer to maintain layout
            Color.clear
                .frame(width: width, height: height)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("100% progress - 4 meals")
            .font(.caption)
        MealProgressBar(
            progress: 1.0,
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
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!,
                    protein: 10,
                    carbs: 50,
                    fats: 5
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!,
                    protein: 30,
                    carbs: 40,
                    fats: 12
                )
            ],
            height: 6
        )
        .padding(.horizontal, 16)

        Text("75% progress - 4 meals")
            .font(.caption)
        MealProgressBar(
            progress: 0.75,
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
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!,
                    protein: 10,
                    carbs: 50,
                    fats: 5
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!,
                    protein: 30,
                    carbs: 40,
                    fats: 12
                )
            ],
            height: 6
        )
        .padding(.horizontal, 16)

        Text("50% progress - 2 meals")
            .font(.caption)
        MealProgressBar(
            progress: 0.5,
            meals: [
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
                    protein: 25,
                    carbs: 40,
                    fats: 12
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date())!,
                    protein: 30,
                    carbs: 35,
                    fats: 15
                )
            ],
            height: 6
        )
        .padding(.horizontal, 16)

        Text("No meals - 30%")
            .font(.caption)
        MealProgressBar(
            progress: 0.3,
            meals: [],
            height: 6
        )
        .padding(.horizontal, 16)
    }
    .padding()
    .background(Color.white)
}
