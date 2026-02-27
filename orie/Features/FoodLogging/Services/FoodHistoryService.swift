//
//  FoodHistoryService.swift
//  orie
//
//  Created by Shareef Evans on 02/02/2026.
//

import Foundation

class FoodHistoryService {
    static let baseURL = APIService.baseURL

    // MARK: - Models

    struct PreviousEntryResponse: Codable {
        let calories: Int?
        let protein: Double?
        let carbs: Double?
        let fats: Double?
        let servingSize: String?

        enum CodingKeys: String, CodingKey {
            case calories, protein, carbs, fats
            case servingSize = "serving_size"
        }
    }

    struct AutocompleteResponse: Codable {
        let suggestions: [String]
    }

    // MARK: - API Methods

    /// Search for a previously logged food by name
    /// Returns the nutrition data if found, nil otherwise
    static func findPreviousEntry(
        accessToken: String,
        foodName: String
    ) async throws -> (calories: Int, protein: Double, carbs: Double, fats: Double, servingSize: String)? {

        guard let url = URL(string: "\(baseURL)/api/food-entries/search") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["food_name": foodName]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if httpResponse.statusCode == 404 {
            return nil // No previous entry found
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            throw APIError.badResponse
        }

        let result = try JSONDecoder().decode(PreviousEntryResponse.self, from: data)

        return (
            calories: result.calories ?? 0,
            protein: result.protein ?? 0,
            carbs: result.carbs ?? 0,
            fats: result.fats ?? 0,
            servingSize: result.servingSize ?? "100g"
        )
    }

    /// Get autocomplete suggestions based on partial input
    static func getAutocompleteSuggestions(
        accessToken: String,
        partialName: String,
        limit: Int = 5
    ) async throws -> [String] {

        guard let url = URL(string: "\(baseURL)/api/food-entries/autocomplete") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "partial_name": partialName,
            "limit": limit
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

        let result = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
        return result.suggestions
    }
}
