//
//  FoodEntry.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import Foundation

struct FoodEntry: Identifiable, Comparable {
    let id = UUID()
    var timestamp: Date
    var entryDate: Date  // Just the day (no time component)
    var foodName: String
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fats: Double?
    var isLoading: Bool
    
    init(foodName: String, entryDate: Date = Date()) {
        self.timestamp = Date()
        self.entryDate = Calendar.current.startOfDay(for: entryDate)
        self.foodName = foodName
        self.calories = nil
        self.protein = nil
        self.carbs = nil
        self.fats = nil
        self.isLoading = true
    }
    
    // Comparable implementation for sorting
    static func < (lhs: FoodEntry, rhs: FoodEntry) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
