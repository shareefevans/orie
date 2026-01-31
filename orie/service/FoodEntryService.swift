//
//  FoodEntryService.swift
//  orie
//
//  Created by Shareef Evans on 18/12/2025.
//

import Foundation

enum APIError: Error {
    case sessionExpired
    case badResponse
    case badURL
}

// MARK: - Weekly Progress Models

struct MacroComparison: Codable {
    let actual: Int
    let goal: Int
    let percentage: Int
    let status: String
}

struct WeeklyAverages: Codable {
    let calories: MacroComparison
    let protein: MacroComparison
    let carbs: MacroComparison
    let fats: MacroComparison
}

struct WeeklyProgressResponse: Codable {
    let daysTracked: Int
    let averages: WeeklyAverages
    let statement: String
    let tip: String?
}

class FoodEntryService {
    static let baseURL = APIService.baseURL
    
    // MARK: - Models
    
    struct FoodEntryDB: Codable {
        let id: String?
        let userId: String?
        let foodName: String
        let calories: Int?
        let protein: Double?
        let carbs: Double?
        let fats: Double?
        let servingSize: String?
        let entryDate: String
        let timestamp: String
        let isLoading: Bool?
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case foodName = "food_name"
            case calories
            case protein
            case carbs
            case fats
            case servingSize = "serving_size"
            case entryDate = "entry_date"
            case timestamp
            case isLoading = "is_loading"
        }
    }
    
    struct FoodEntriesResponse: Codable {
        let entries: [FoodEntryDB]
    }
    
    struct FoodEntryResponse: Codable {
        let entry: FoodEntryDB
    }
    
    // MARK: - API Methods
    
    static func getFoodEntries(accessToken: String, date: Date?) async throws -> [FoodEntryDB] {
        var urlString = "\(baseURL)/api/food-entries"
        
        if let date = date {
            let dateString = ISO8601DateFormatter().string(from: date).prefix(10)
            urlString += "?date=\(dateString)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            throw APIError.badResponse
        }

        let result = try JSONDecoder().decode(FoodEntriesResponse.self, from: data)
        return result.entries
    }
    
    static func createFoodEntry(accessToken: String, entry: FoodEntry) async throws -> FoodEntryDB {
        guard let url = URL(string: "\(baseURL)/api/food-entries") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let iso8601 = ISO8601DateFormatter()
        let entryDateString = String(iso8601.string(from: entry.entryDate).prefix(10))
        let timestampString = iso8601.string(from: entry.timestamp)
        
        let body: [String: Any] = [
            "food_name": entry.foodName,
            "calories": entry.calories ?? NSNull(),
            "protein": entry.protein ?? NSNull(),
            "carbs": entry.carbs ?? NSNull(),
            "fats": entry.fats ?? NSNull(),
            "serving_size": entry.servingSize ?? NSNull(),
            "entry_date": entryDateString,
            "timestamp": timestampString
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            throw APIError.badResponse
        }

        let result = try JSONDecoder().decode(FoodEntryResponse.self, from: data)
        return result.entry
    }

    static func updateFoodEntry(accessToken: String, id: String, timestamp: Date) async throws -> FoodEntryDB {
        guard let url = URL(string: "\(baseURL)/api/food-entries/\(id)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let iso8601 = ISO8601DateFormatter()
        let timestampString = iso8601.string(from: timestamp)

        let body: [String: Any] = [
            "timestamp": timestampString
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            throw APIError.badResponse
        }

        let result = try JSONDecoder().decode(FoodEntryResponse.self, from: data)
        return result.entry
    }

    static func updateFoodEntry(accessToken: String, id: String, entry: FoodEntry) async throws -> FoodEntryDB {
        guard let url = URL(string: "\(baseURL)/api/food-entries/\(id)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let iso8601 = ISO8601DateFormatter()
        let timestampString = iso8601.string(from: entry.timestamp)

        let body: [String: Any] = [
            "food_name": entry.foodName,
            "calories": entry.calories ?? NSNull(),
            "protein": entry.protein ?? NSNull(),
            "carbs": entry.carbs ?? NSNull(),
            "fats": entry.fats ?? NSNull(),
            "serving_size": entry.servingSize ?? NSNull(),
            "timestamp": timestampString
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            throw APIError.badResponse
        }

        let result = try JSONDecoder().decode(FoodEntryResponse.self, from: data)
        return result.entry
    }

    static func deleteFoodEntry(accessToken: String, id: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/food-entries/\(id)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            throw APIError.badResponse
        }
    }

    // MARK: - Weekly Progress

    static func getWeeklyProgress(accessToken: String, forceRefresh: Bool = false) async throws -> WeeklyProgressResponse {
        var urlString = "\(baseURL)/api/progress/weekly"
        if forceRefresh {
            urlString += "?refresh=true"
        }

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            throw APIError.badResponse
        }

        let result = try JSONDecoder().decode(WeeklyProgressResponse.self, from: data)
        return result
    }
}
