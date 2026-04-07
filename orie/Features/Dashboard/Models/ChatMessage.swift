//
//  ChatMessage.swift
//  orie
//

import Foundation

struct MealSuggestion: Codable, Equatable {
    let foodName: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let servingSize: String
    var isAdded: Bool = false
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    let role: Role
    let content: String
    var mealSuggestion: MealSuggestion? = nil

    enum Role: String, Codable {
        case user, assistant
    }
}
