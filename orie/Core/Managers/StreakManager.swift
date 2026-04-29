//
//  StreakManager.swift
//  orie
//

import Foundation

class StreakManager {
    static let shared = StreakManager()

    private let streakCountKey = "streak_count"

    private init() {}

    /// Update the cached streak value from the backend response.
    func update(to count: Int) {
        UserDefaults.standard.set(count, forKey: streakCountKey)
    }

    var currentStreak: Int {
        let count = UserDefaults.standard.integer(forKey: streakCountKey)
        return max(count, 0)
    }
}
