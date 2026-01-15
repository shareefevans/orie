//
//  FoodEntry.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import Foundation

struct NutritionSource: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let url: String
    let icon: String

    enum CodingKeys: String, CodingKey {
        case name, url, icon
    }

    static func == (lhs: NutritionSource, rhs: NutritionSource) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url && lhs.icon == rhs.icon
    }
}

struct FoodEntry: Identifiable, Comparable {
    let id = UUID()
    var dbId: String? // ← Add this for Supabase ID
    var timestamp: Date
    var entryDate: Date
    var foodName: String
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fats: Double?
    var servingSize: String?
    var imageUrl: String?
    var sources: [NutritionSource]?
    var isLoading: Bool

    init(foodName: String, entryDate: Date = Date()) {
        self.timestamp = Date()
        self.entryDate = Calendar.current.startOfDay(for: entryDate)
        self.foodName = foodName
        self.dbId = nil // ← Initialize as nil
        self.calories = nil
        self.protein = nil
        self.carbs = nil
        self.fats = nil
        self.servingSize = nil
        self.imageUrl = nil
        self.sources = nil
        self.isLoading = true
    }

    // Comparable implementation for sorting
    static func < (lhs: FoodEntry, rhs: FoodEntry) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
