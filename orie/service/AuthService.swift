//
//  AuthService.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import Foundation
import AuthenticationServices

class AuthService {
    static let baseURL = APIService.baseURL

    // MARK: - Response Models

    struct AuthResponse: Codable {
        let message: String?
        let user: User?
        let session: Session?
        let error: String?
    }

    struct User: Codable {
        let id: String
        let email: String?
        let userMetadata: UserMetadata?

        enum CodingKeys: String, CodingKey {
            case id, email
            case userMetadata = "user_metadata"
        }
    }

    struct UserMetadata: Codable {
        let fullName: String?

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
        }
    }

    struct Session: Codable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int?
        let expiresAt: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
        }

        init(accessToken: String, refreshToken: String, expiresIn: Int? = nil, expiresAt: Int? = nil) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expiresIn = expiresIn
            self.expiresAt = expiresAt
        }
    }

    struct OAuthURLResponse: Codable {
        let url: String?
        let error: String?
    }

    struct UserProfile: Codable {
        let fullName: String?
        let gender: String?
        let age: Int?
        let height: Double?
        let weight: Double?
        let dailyCalories: Int?
        let dailyProtein: Int?
        let dailyCarbs: Int?
        let dailyFats: Int?

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case gender, age, height, weight
            case dailyCalories = "daily_calories"
            case dailyProtein = "daily_protein"
            case dailyCarbs = "daily_carbs"
            case dailyFats = "daily_fats"
        }
    }

    struct ProfileResponse: Codable {
        let profile: UserProfile?
        let error: String?
    }

    // MARK: - Auth Methods

    static func signUp(email: String, password: String, fullName: String?) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/signup") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "email": email,
            "password": password
        ]
        if let fullName = fullName {
            body["fullName"] = fullName
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError(authResponse.error ?? "Unknown error")
        }

        return authResponse
    }

    static func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError(authResponse.error ?? "Invalid credentials")
        }

        return authResponse
    }

    static func getGoogleOAuthURL() async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/auth/google") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OAuthURLResponse.self, from: data)

        guard let oauthURL = response.url else {
            throw AuthError.serverError(response.error ?? "Failed to get OAuth URL")
        }

        return oauthURL
    }

    static func signInWithApple(identityToken: String, fullName: String?, email: String?) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/apple/native") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["identityToken": identityToken]
        if let fullName = fullName { body["fullName"] = fullName }
        if let email = email { body["email"] = email }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError(authResponse.error ?? "Apple sign-in failed")
        }

        return authResponse
    }

    static func exchangeCodeForSession(code: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/callback") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["code": code]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError(authResponse.error ?? "Failed to exchange code")
        }

        return authResponse
    }

    static func refreshSession(refreshToken: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/refresh") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["refreshToken": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError(authResponse.error ?? "Failed to refresh session")
        }

        return authResponse
    }

    static func logout() async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/logout") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode < 400 else {
            throw URLError(.badServerResponse)
        }
    }

    static func getCurrentUser(accessToken: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/api/auth/me") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError("Failed to fetch user")
        }

        struct UserResponse: Codable {
            let user: User
        }

        let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
        return userResponse.user
    }

    // MARK: - Profile Methods

    static func getProfile(accessToken: String) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/profile") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError("Failed to fetch profile")
        }

        let profileResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)

        guard let profile = profileResponse.profile else {
            throw AuthError.serverError(profileResponse.error ?? "No profile data")
        }

        return profile
    }

    static func updateProfile(
        accessToken: String,
        fullName: String? = nil,
        gender: String? = nil,
        age: Int? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        dailyCalories: Int? = nil,
        dailyProtein: Int? = nil,
        dailyCarbs: Int? = nil,
        dailyFats: Int? = nil
    ) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/profile") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [:]
        if let fullName = fullName { body["full_name"] = fullName }
        if let gender = gender { body["gender"] = gender }
        if let age = age { body["age"] = age }
        if let height = height { body["height"] = height }
        if let weight = weight { body["weight"] = weight }
        if let dailyCalories = dailyCalories { body["daily_calories"] = dailyCalories }
        if let dailyProtein = dailyProtein { body["daily_protein"] = dailyProtein }
        if let dailyCarbs = dailyCarbs { body["daily_carbs"] = dailyCarbs }
        if let dailyFats = dailyFats { body["daily_fats"] = dailyFats }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        if httpResponse.statusCode >= 400 {
            throw AuthError.serverError("Failed to update profile")
        }

        let profileResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)

        guard let profile = profileResponse.profile else {
            throw AuthError.serverError(profileResponse.error ?? "No profile data")
        }

        return profile
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case serverError(String)
    case invalidCredentials
    case noSession

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .invalidCredentials:
            return "Invalid email or password"
        case .noSession:
            return "No active session"
        }
    }
}
