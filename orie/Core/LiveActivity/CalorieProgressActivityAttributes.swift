//
//  CalorieProgressActivityAttributes.swift
//  orie
//
//  All-day calorie tracking Live Activity
//

import ActivityKit
import Foundation
import SwiftUI
import Combine

/// Attributes for the all-day calorie progress Live Activity
@available(iOS 16.1, *)
struct CalorieProgressActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Current calories consumed
        var consumedCalories: Int

        /// Daily calorie goal
        var goalCalories: Int

        /// Protein consumed
        var consumedProtein: Int

        /// Protein goal
        var goalProtein: Int

        /// Carbs consumed
        var consumedCarbs: Int

        /// Carbs goal
        var goalCarbs: Int

        /// Fats consumed
        var consumedFats: Int

        /// Fats goal
        var goalFats: Int

        /// Time when last updated
        var lastUpdated: Date

        // Computed properties
        var remainingCalories: Int {
            goalCalories - consumedCalories
        }

        var progress: Double {
            guard goalCalories > 0 else { return 0 }
            return min(Double(consumedCalories) / Double(goalCalories), 1.0)
        }

        var isOverGoal: Bool {
            consumedCalories > goalCalories
        }

        var proteinProgress: Double {
            guard goalProtein > 0 else { return 0 }
            return min(Double(consumedProtein) / Double(goalProtein), 1.0)
        }

        var carbsProgress: Double {
            guard goalCarbs > 0 else { return 0 }
            return min(Double(consumedCarbs) / Double(goalCarbs), 1.0)
        }

        var fatsProgress: Double {
            guard goalFats > 0 else { return 0 }
            return min(Double(consumedFats) / Double(goalFats), 1.0)
        }
    }

    /// Static data - date this activity started
    var startDate: Date
}

// MARK: - Activity Manager

@available(iOS 16.1, *)
class CalorieProgressActivityManager: ObservableObject {
    static let shared = CalorieProgressActivityManager()

    @Published private(set) var currentActivity: Activity<CalorieProgressActivityAttributes>?

    private init() {}

    /// Start the all-day calorie tracking Live Activity
    @MainActor
    func startCalorieTracking(
        consumedCalories: Int,
        goalCalories: Int,
        consumedProtein: Int,
        goalProtein: Int,
        consumedCarbs: Int,
        goalCarbs: Int,
        consumedFats: Int,
        goalFats: Int
    ) {
        // Don't start a new one if already running
        guard currentActivity == nil else {
            updateCalorieProgress(
                consumedCalories: consumedCalories,
                goalCalories: goalCalories,
                consumedProtein: consumedProtein,
                goalProtein: goalProtein,
                consumedCarbs: consumedCarbs,
                goalCarbs: goalCarbs,
                consumedFats: consumedFats,
                goalFats: goalFats
            )
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities are not enabled")
            return
        }

        let attributes = CalorieProgressActivityAttributes(startDate: Date())
        let initialState = CalorieProgressActivityAttributes.ContentState(
            consumedCalories: consumedCalories,
            goalCalories: goalCalories,
            consumedProtein: consumedProtein,
            goalProtein: goalProtein,
            consumedCarbs: consumedCarbs,
            goalCarbs: goalCarbs,
            consumedFats: consumedFats,
            goalFats: goalFats,
            lastUpdated: Date()
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("✅ Calorie Progress Live Activity started")

            // Auto-dismiss at midnight
            scheduleEndOfDayDismissal()
        } catch {
            print("❌ Failed to start calorie tracking activity: \(error)")
        }
    }

    /// Update the calorie progress
    @MainActor
    func updateCalorieProgress(
        consumedCalories: Int,
        goalCalories: Int,
        consumedProtein: Int,
        goalProtein: Int,
        consumedCarbs: Int,
        goalCarbs: Int,
        consumedFats: Int,
        goalFats: Int
    ) {
        guard let activity = currentActivity else { return }

        Task {
            let updatedState = CalorieProgressActivityAttributes.ContentState(
                consumedCalories: consumedCalories,
                goalCalories: goalCalories,
                consumedProtein: consumedProtein,
                goalProtein: goalProtein,
                consumedCarbs: consumedCarbs,
                goalCarbs: goalCarbs,
                consumedFats: consumedFats,
                goalFats: goalFats,
                lastUpdated: Date()
            )

            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: nil
                )
            )
            print("🔄 Calorie Progress updated: \(consumedCalories)/\(goalCalories)")
        }
    }

    /// End the calorie tracking activity
    @MainActor
    func endCalorieTracking() {
        guard let activity = currentActivity else { return }

        Task {
            let finalState = activity.content.state
            await activity.end(
                ActivityContent(
                    state: finalState,
                    staleDate: Date()
                ),
                dismissalPolicy: .immediate
            )
            await MainActor.run {
                currentActivity = nil
            }
            print("🛑 Calorie Progress Live Activity ended")
        }
    }

    /// Schedule auto-dismissal at midnight
    private func scheduleEndOfDayDismissal() {
        Task { @MainActor in
            let calendar = Calendar.current
            let now = Date()

            // Get midnight tonight
            if let midnight = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now),
               midnight > now {
                let timeUntilMidnight = midnight.timeIntervalSince(now)

                try? await Task.sleep(for: .seconds(timeUntilMidnight))
                endCalorieTracking()
            }
        }
    }
}
