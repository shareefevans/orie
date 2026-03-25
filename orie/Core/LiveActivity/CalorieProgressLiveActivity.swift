//
//  CalorieProgressLiveActivity.swift
//  orie
//
//  Dynamic Island presentation for all-day calorie tracking
//

import ActivityKit
import SwiftUI
import WidgetKit

/// Format calorie value with k suffix for values >= 1000
private func formatCalories(_ calories: Int) -> String {
    if calories >= 1000 {
        let value = Double(calories) / 1000.0
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fk", value)
        } else {
            return String(format: "%.1fk", value)
        }
    }
    return "\(calories)"
}

@available(iOS 16.2, *)
struct CalorieProgressLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CalorieProgressActivityAttributes.self) { context in
            // Lock screen / banner UI
            LockScreenCalorieView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.2))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view - Horizontal donut charts
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 0) {
                        // Streak (Far left)
                        StreakDisplay(streakDays: context.state.streakDays)

                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 1, height: 15)
                            .padding(.horizontal, 24)

                        // Calories
                        MacroDonutChart(
                            label: "Calories",
                            value: context.state.consumedCalories,
                            progress: context.state.progress,
                            showUnit: false
                        )

                        Spacer()

                        // Protein
                        MacroDonutChart(
                            label: "Protein",
                            value: context.state.consumedProtein,
                            progress: context.state.proteinProgress,
                            showUnit: true
                        )

                        Spacer()

                        // Carbs
                        MacroDonutChart(
                            label: "Carbs",
                            value: context.state.consumedCarbs,
                            progress: context.state.carbsProgress,
                            showUnit: true
                        )

                        Spacer()

                        // Fats
                        MacroDonutChart(
                            label: "Fats",
                            value: context.state.consumedFats,
                            progress: context.state.fatsProgress,
                            showUnit: true
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            } compactLeading: {
                // Compact view - Total calories consumed
                HStack(spacing: 0) {
                    Text(formatCalories(context.state.consumedCalories))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("cal")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.leading, 2)
            } compactTrailing: {
                // Compact view - Small progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2.5)
                        .frame(width: 16, height: 16)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(
                            context.state.isOverGoal ? Color.red : Color.green,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-90))
                }
                .padding(.leading, 1)
            } minimal: {
                // Minimal view - Just calories text (when another app uses Dynamic Island)
                HStack(spacing: 1) {
                    Text(formatCalories(context.state.consumedCalories))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("cal")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .keylineTint(context.state.isOverGoal ? Color.red : Color.green)
        }
    }
}

@available(iOS 16.2, *)
struct LockScreenCalorieView: View {
    let context: ActivityViewContext<CalorieProgressActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(
                        context.state.isOverGoal ? Color.red : Color.green,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(context.state.progress * 100))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(context.state.consumedCalories)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("/ \(context.state.goalCalories) cal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Text("\(abs(context.state.remainingCalories)) \(context.state.isOverGoal ? "over goal" : "remaining")")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(
                        context.state.isOverGoal ? .red : .white.opacity(0.8)
                    )
            }

            Spacer()
        }
        .padding(12)
    }
}

@available(iOS 16.2, *)
struct StreakDisplay: View {
    let streakDays: Int

    var body: some View {
        VStack(spacing: 4) {
            // Flame icon - same height as donut charts
            Text("🔥")
                .font(.system(size: 17))

            // Streak label
            Text("Streak")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            // Streak days
            Text("\(streakDays) days")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

@available(iOS 16.2, *)
struct MacroDonutChart: View {
    let label: String
    let value: Int
    let progress: Double
    let showUnit: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Donut chart
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 18, height: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-90))
            }

            // Label
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            // Value
            Text(showUnit ? "\(value)g" : "\(value)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
