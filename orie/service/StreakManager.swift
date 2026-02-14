//
//  StreakManager.swift
//  orie
//

import Foundation

class StreakManager {
    static let shared = StreakManager()

    private let lastOpenedKey = "streak_lastOpenedDate"
    private let streakCountKey = "streak_count"

    private let calendar = Calendar.current

    private init() {}

    /// Call this once per app launch to update the streak.
    func recordAppOpen() {
        let today = calendar.startOfDay(for: Date())

        if let lastDate = UserDefaults.standard.object(forKey: lastOpenedKey) as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 0 {
                // Already opened today, no change
                return
            } else if daysBetween == 1 {
                // Consecutive day — increment streak
                let current = UserDefaults.standard.integer(forKey: streakCountKey)
                UserDefaults.standard.set(current + 1, forKey: streakCountKey)
            } else {
                // Streak broken — reset to 1
                UserDefaults.standard.set(1, forKey: streakCountKey)
            }
        } else {
            // First ever open
            UserDefaults.standard.set(1, forKey: streakCountKey)
        }

        UserDefaults.standard.set(today, forKey: lastOpenedKey)
    }

    var currentStreak: Int {
        let count = UserDefaults.standard.integer(forKey: streakCountKey)
        return max(count, 0)
    }
}
