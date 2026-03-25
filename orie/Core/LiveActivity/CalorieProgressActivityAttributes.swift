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

        /// Current streak days
        var streakDays: Int

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
    private var monitorTask: Task<Void, Never>?
    private var dismissalTask: Task<Void, Never>?

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
        goalFats: Int,
        streakDays: Int = 0
    ) {
        // If already running, update it and restart the timer
        if currentActivity != nil {
            print("🔄 Updating existing activity and restarting timer")
            updateCalorieProgress(
                consumedCalories: consumedCalories,
                goalCalories: goalCalories,
                consumedProtein: consumedProtein,
                goalProtein: goalProtein,
                consumedCarbs: consumedCarbs,
                goalCarbs: goalCarbs,
                consumedFats: consumedFats,
                goalFats: goalFats,
                streakDays: streakDays
            )
            // Restart the dismissal timer
            scheduleAutoDismissal()
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
            streakDays: streakDays,
            lastUpdated: Date()
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("✅ Calorie Progress Live Activity started (will auto-dismiss in 10 seconds)")

            // Monitor activity state to detect dismissal
            monitorActivityState(activity)

            // Schedule forced dismissal after 10 seconds
            scheduleAutoDismissal()
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
        goalFats: Int,
        streakDays: Int = 0
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
                streakDays: streakDays,
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

    /// Monitor activity state to detect when it's dismissed
    private func monitorActivityState(_ activity: Activity<CalorieProgressActivityAttributes>) {
        monitorTask?.cancel()
        monitorTask = Task { @MainActor in
            for await state in activity.activityStateUpdates {
                if state == .dismissed || state == .ended {
                    print("🔔 Live Activity dismissed/ended by system")
                    currentActivity = nil
                    monitorTask?.cancel()
                    break
                }
            }
        }
    }

    /// End the calorie tracking activity
    @MainActor
    func endCalorieTracking() {
        guard let activity = currentActivity else {
            print("⚠️ No activity to end")
            return
        }

        Task {
            // Set stale date to past to force immediate dismissal
            let pastDate = Calendar.current.date(byAdding: .second, value: -10, to: Date()) ?? Date()
            let finalState = activity.content.state

            await activity.end(
                ActivityContent(
                    state: finalState,
                    staleDate: pastDate
                ),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                currentActivity = nil
                monitorTask?.cancel()
                dismissalTask?.cancel()
            }
            print("✅ Calorie Progress Live Activity ended successfully")
        }
    }

    /// Schedule auto-dismissal after 10 seconds
    private func scheduleAutoDismissal() {
        dismissalTask?.cancel()
        dismissalTask = Task { @MainActor in
            print("⏱️ Dismissal timer started - will dismiss in 10 seconds")

            // Wait 10 seconds
            try? await Task.sleep(for: .seconds(10))

            guard !Task.isCancelled else {
                print("⚠️ Dismissal task was cancelled")
                return
            }

            // Time's up, force dismiss the activity
            print("⏰ 10 seconds elapsed - calling endCalorieTracking()")
            endCalorieTracking()
        }
    }
}
