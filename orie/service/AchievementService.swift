//
//  AchievementService.swift
//  orie
//
//  Created by Shareef Evans on 01/02/2026.
//

import Foundation

// MARK: - Achievement Models

struct Achievement: Codable, Identifiable {
    let achievementId: String
    let name: String
    let description: String
    let category: String
    let image: String
    let currentProgress: Int
    let target: Int
    let percentage: Int
    let isUnlocked: Bool
    let unlockedAt: String?

    var id: String { achievementId }

    enum CodingKeys: String, CodingKey {
        case achievementId = "achievement_id"
        case name
        case description
        case category
        case image
        case currentProgress = "current_progress"
        case target
        case percentage
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
    }
}

struct AchievementsResponse: Codable {
    let achievements: [Achievement]
    let totalUnlocked: Int
    let totalAchievements: Int
}

struct AchievementSyncResponse: Codable {
    let message: String
    let achievements: [Achievement]
    let newlyUnlocked: [Achievement]
}

// MARK: - Achievement Service

class AchievementService {
    static let baseURL = APIService.baseURL

    // MARK: - Get All Achievements with Progress

    static func getAchievements(accessToken: String) async throws -> AchievementsResponse {
        guard let url = URL(string: "\(baseURL)/api/achievements") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        print("📡 Fetching achievements from: \(url)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        print("📡 Achievement response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        guard httpResponse.statusCode < 400 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Achievement error response: \(responseString)")
            }
            throw APIError.badResponse
        }

        // Debug: print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Achievement raw response: \(responseString.prefix(500))")
        }

        do {
            let result = try JSONDecoder().decode(AchievementsResponse.self, from: data)
            print("✅ Decoded \(result.achievements.count) achievements")
            return result
        } catch {
            print("❌ JSON decode error: \(error)")
            throw error
        }
    }

    // MARK: - Get Unlocked Achievements Only

    static func getUnlockedAchievements(accessToken: String) async throws -> AchievementsResponse {
        guard let url = URL(string: "\(baseURL)/api/achievements/unlocked") else {
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

        let result = try JSONDecoder().decode(AchievementsResponse.self, from: data)
        return result
    }

    // MARK: - Sync Achievements (Refresh Progress)

    static func syncAchievements(accessToken: String) async throws -> AchievementSyncResponse {
        guard let url = URL(string: "\(baseURL)/api/achievements/sync") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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

        let result = try JSONDecoder().decode(AchievementSyncResponse.self, from: data)
        return result
    }
}
