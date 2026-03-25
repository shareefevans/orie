//
//  CalorieProgressLiveActivity.swift
//  orie
//
//  Dynamic Island presentation for all-day calorie tracking
//

import ActivityKit
import SwiftUI
import WidgetKit

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
                // Expanded view - Full macro breakdown
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Calories
                        HStack(spacing: 4) {
                            Text("\(context.state.consumedCalories)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("/ \(context.state.goalCalories)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Text("cal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        let remaining = context.state.remainingCalories
                        Text("\(abs(remaining))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(
                                context.state.isOverGoal ? .red : .green
                            )

                        Text(context.state.isOverGoal ? "over" : "left")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Macro bars
                    VStack(spacing: 8) {
                        // Protein
                        MacroProgressRow(
                            label: "Protein",
                            value: context.state.consumedProtein,
                            goal: context.state.goalProtein,
                            progress: context.state.proteinProgress,
                            color: Color(red: 49/255, green: 209/255, blue: 149/255)
                        )

                        // Carbs
                        MacroProgressRow(
                            label: "Carbs",
                            value: context.state.consumedCarbs,
                            goal: context.state.goalCarbs,
                            progress: context.state.carbsProgress,
                            color: Color(red: 135/255, green: 206/255, blue: 250/255)
                        )

                        // Fats
                        MacroProgressRow(
                            label: "Fats",
                            value: context.state.consumedFats,
                            goal: context.state.goalFats,
                            progress: context.state.fatsProgress,
                            color: Color(red: 255/255, green: 180/255, blue: 50/255)
                        )
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact view - Calorie count with progress ring
                ZStack {
                    // Progress ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(
                            context.state.isOverGoal ? Color.red : Color.green,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))

                    // Calorie count
                    Text("\(context.state.consumedCalories)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // Compact view - Remaining calories
                HStack(spacing: 2) {
                    Text("\(abs(context.state.remainingCalories))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(
                            context.state.isOverGoal ? .red : .white
                        )
                    Text(context.state.isOverGoal ? "+" : "")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(context.state.isOverGoal ? .red : .white.opacity(0.7))
                }
            } minimal: {
                // Minimal view - Just progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)

                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(
                            context.state.isOverGoal ? Color.red : Color.green,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 20, height: 20)
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
struct MacroProgressRow: View {
    let label: String
    let value: Int
    let goal: Int
    let progress: Double
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 50, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)

            Text("\(value)g")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 35, alignment: .trailing)
        }
    }
}
