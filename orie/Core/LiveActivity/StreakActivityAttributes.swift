//
//  StreakActivityAttributes.swift
//  orie
//
//  Created for Dynamic Island streak counter
//

import ActivityKit
import Foundation
import SwiftUI
import Combine

/// Attributes for the streak celebration Live Activity
@available(iOS 16.1, *)
struct StreakActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Current streak count
        var streakDays: Int

        /// Time when the streak was updated
        var lastUpdated: Date
    }

    /// Static data that doesn't change during the activity
    var isFirstEntryOfDay: Bool
}

// MARK: - Activity Manager

@available(iOS 16.1, *)
class StreakActivityManager: ObservableObject {
    static let shared = StreakActivityManager()

    @Published private(set) var currentActivity: Activity<StreakActivityAttributes>?

    private init() {}

    /// Start the streak celebration Live Activity
    @MainActor
    func startStreakCelebration(streakDays: Int) {
        // End any existing activity first
        endStreakCelebration()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities are not enabled")
            return
        }

        let attributes = StreakActivityAttributes(isFirstEntryOfDay: true)
        let initialState = StreakActivityAttributes.ContentState(
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
            print("✅ Streak Live Activity started: \(streakDays) days")

            // Auto-dismiss after 8 seconds
            Task {
                try? await Task.sleep(for: .seconds(8))
                endStreakCelebration()
            }
        } catch {
            print("❌ Failed to start streak activity: \(error)")
        }
    }

    /// End the current streak celebration
    @MainActor
    func endStreakCelebration() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(
                ActivityContent(
                    state: activity.content.state,
                    staleDate: Date()
                ),
                dismissalPolicy: .immediate
            )
            currentActivity = nil
            print("🛑 Streak Live Activity ended")
        }
    }

    /// Update the streak count (if needed)
    @MainActor
    func updateStreak(to newStreak: Int) {
        guard let activity = currentActivity else { return }

        Task {
            let updatedState = StreakActivityAttributes.ContentState(
                streakDays: newStreak,
                lastUpdated: Date()
            )

            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }
}
