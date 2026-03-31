//
//  APIService.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import Foundation

class APIService {
    static let baseURL = "https://oriebackend.onrender.com"

    // MARK: - Nutrition Models

    struct NutritionResponse: Codable {
        let foodName: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fats: Double
        let fibre: Double?
        let sodium: Double?
        let sugar: Double?
        let servingSize: String
        let imageUrl: String?
        let sources: [NutritionSource]?
    }

    struct NutritionRequest: Codable {
        let foodItem: String
    }

    struct ImageAnalysisResponse: Codable {
        let description: String
        let confidence: String
        let nutrition: ImageNutritionData
    }

    struct ImageNutritionData: Codable {
        let foodName: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fats: Double
        let fibre: Double?
        let sodium: Double?
        let sugar: Double?
        let servingSize: String
        let imageUrl: String?
        let sources: [NutritionSource]?
    }

    struct ImageAnalysisRequest: Codable {
        let image: String
    }

    // MARK: - Subscription Models

    struct SubscriptionStatus: Codable {
        let tier: String
        let status: String
        let expiresAt: String?
        let aiUsedToday: Int
        let aiLimit: Int
    }

    // MARK: - AI Endpoints (require auth + premium subscription)

    static func getNutrition(for foodItem: String, accessToken: String) async throws -> NutritionResponse {
        guard let url = URL(string: "\(baseURL)/api/nutrition") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(NutritionRequest(foodItem: foodItem))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(NutritionResponse.self, from: data)
        case 401:
            throw APIError.sessionExpired
        case 403:
            throw APIError.upgradeRequired
        case 429:
            throw APIError.aiLimitReached
        default:
            throw URLError(.badServerResponse)
        }
    }

    static func analyzeImageWithNutrition(imageBase64: String, accessToken: String) async throws -> ImageAnalysisResponse {
        guard let url = URL(string: "\(baseURL)/api/image/analyze-with-nutrition") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(ImageAnalysisRequest(image: imageBase64))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(ImageAnalysisResponse.self, from: data)
        case 401:
            throw APIError.sessionExpired
        case 403:
            throw APIError.upgradeRequired
        case 429:
            throw APIError.aiLimitReached
        default:
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Subscription Endpoints

    static func getSubscriptionStatus(accessToken: String) async throws -> SubscriptionStatus {
        guard let url = URL(string: "\(baseURL)/api/subscriptions/status") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 { throw APIError.sessionExpired }
        guard (200...299).contains(httpResponse.statusCode) else { throw URLError(.badServerResponse) }

        return try JSONDecoder().decode(SubscriptionStatus.self, from: data)
    }

    static func selectFreeTier(accessToken: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/subscriptions/select-free") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode([String: String]())

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 { throw APIError.sessionExpired }
        guard (200...299).contains(httpResponse.statusCode) else { throw URLError(.badServerResponse) }
    }

    static func selectPremiumTier(accessToken: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/subscriptions/select-premium") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode([String: String]())

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 { throw APIError.sessionExpired }
        guard (200...299).contains(httpResponse.statusCode) else { throw URLError(.badServerResponse) }
    }

    static func verifyAppleTransaction(accessToken: String, jwsRepresentation: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/subscriptions/apple/verify") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["jwsRepresentation": jwsRepresentation])

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 { throw APIError.sessionExpired }
        guard (200...299).contains(httpResponse.statusCode) else { throw URLError(.badServerResponse) }
    }

    // MARK: - Chat

    struct ChatMessagePayload: Codable {
        let role: String
        let content: String
    }

    struct ChatContext: Codable {
        let remainingCalories: Int
        let consumedCalories: Int
        let consumedProtein: Int
        let consumedCarbs: Int
        let consumedFats: Int
        let calorieGoal: Int
        let proteinGoal: Int
        let carbsGoal: Int
        let foodEntries: [String]
    }

    struct ChatRequest: Codable {
        let messages: [ChatMessagePayload]
        let context: ChatContext
    }

    struct ChatResponse: Codable {
        let message: String
    }

    static func chat(
        messages: [ChatMessagePayload],
        context: ChatContext,
        accessToken: String
    ) async throws -> ChatResponse {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(ChatRequest(messages: messages, context: context))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(ChatResponse.self, from: data)
        case 401:
            throw APIError.sessionExpired
        case 403:
            throw APIError.upgradeRequired
        case 429:
            throw APIError.aiLimitReached
        default:
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Feedback

    struct FeedbackRequest: Codable {
        let name: String
        let email: String
        let message: String
    }

    static func sendFeedback(accessToken: String, name: String, email: String, message: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/feedback") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(FeedbackRequest(name: name, email: email, message: message))

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 { throw APIError.sessionExpired }
        guard (200...299).contains(httpResponse.statusCode) else { throw URLError(.badServerResponse) }
    }

}
