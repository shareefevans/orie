//
//  AuthManager.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: AuthService.User?
    @Published var errorMessage: String?

    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"

    init() {
        checkAuthState()
    }

    // MARK: - Auth State

    func checkAuthState() {
        isLoading = true

        // If we have a refresh token, try to get a fresh session
        if let _ = getRefreshToken() {
            Task {
                await refreshSession()
                await MainActor.run {
                    isLoading = false
                }
            }
        } else {
            isAuthenticated = false
            isLoading = false
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, fullName: String?) async {
        errorMessage = nil

        do {
            let response = try await AuthService.signUp(email: email, password: password, fullName: fullName)

            if let session = response.session {
                saveSession(session)
                currentUser = response.user
                isAuthenticated = true
            } else {
                // Email confirmation might be required
                errorMessage = "Please check your email to confirm your account"
            }
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        errorMessage = nil

        do {
            let response = try await AuthService.login(email: email, password: password)

            if let session = response.session {
                saveSession(session)
                currentUser = response.user
                isAuthenticated = true
            }
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
    }

    // MARK: - OAuth

    func getGoogleOAuthURL() async -> String? {
        do {
            return try await AuthService.getGoogleOAuthURL()
        } catch {
            errorMessage = "Failed to initiate Google sign-in"
            return nil
        }
    }

    func getAppleOAuthURL() async -> String? {
        do {
            return try await AuthService.getAppleOAuthURL()
        } catch {
            errorMessage = "Failed to initiate Apple sign-in"
            return nil
        }
    }

    func handleOAuthCallback(code: String) async {
        errorMessage = nil

        do {
            let response = try await AuthService.exchangeCodeForSession(code: code)

            if let session = response.session {
                saveSession(session)
                currentUser = response.user
                isAuthenticated = true
            }
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to complete sign-in"
        }
    }

    // MARK: - Logout

    func logout() async {
        do {
            try await AuthService.logout()
        } catch {
            // Continue with local logout even if server logout fails
        }

        clearSession()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Session Management

    private func saveSession(_ session: AuthService.Session) {
        UserDefaults.standard.set(session.accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(session.refreshToken, forKey: refreshTokenKey)
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }

    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    // MARK: - Refresh Session

    func refreshSession() async {
        guard let refreshToken = getRefreshToken() else {
            isAuthenticated = false
            return
        }

        do {
            let response = try await AuthService.refreshSession(refreshToken: refreshToken)

            if let session = response.session {
                saveSession(session)
                currentUser = response.user
                isAuthenticated = true
            }
        } catch {
            // Refresh failed, user needs to login again
            clearSession()
            isAuthenticated = false
        }
    }
}
