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
}
