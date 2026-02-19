//
//  APIService.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import Foundation

class APIService {
    // Change this to your computer's local IP when testing on device
    // Or use localhost when testing on simulator
    //static let baseURL = "http://192.168.1.227:3000"
    // static let baseURL = "http://localhost:3000"
    static let baseURL = "https://oriebackend.onrender.com"

    struct NutritionResponse: Codable {
        let foodName: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fats: Double
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
        let servingSize: String
        let imageUrl: String?
        let sources: [NutritionSource]?
    }

    struct ImageAnalysisRequest: Codable {
        let image: String
    }

    static func getNutrition(for foodItem: String) async throws -> NutritionResponse {
        guard let url = URL(string: "\(baseURL)/api/nutrition") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = NutritionRequest(foodItem: foodItem)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let nutritionData = try JSONDecoder().decode(NutritionResponse.self, from: data)
        return nutritionData
    }

    static func analyzeImageWithNutrition(imageBase64: String) async throws -> ImageAnalysisResponse {
        guard let url = URL(string: "\(baseURL)/api/image/analyze-with-nutrition") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Image analysis may take longer

        let requestBody = ImageAnalysisRequest(image: imageBase64)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let analysisData = try JSONDecoder().decode(ImageAnalysisResponse.self, from: data)
        return analysisData
    }

    // MARK: 👉 Send Feedback
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

        let feedbackBody = FeedbackRequest(name: name, email: email, message: message)
        request.httpBody = try JSONEncoder().encode(feedbackBody)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
