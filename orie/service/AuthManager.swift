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

    func signInWithApple(identityToken: String, fullName: String?, email: String?) async {
        errorMessage = nil

        do {
            let response = try await AuthService.signInWithApple(
                identityToken: identityToken,
                fullName: fullName,
                email: email
            )

            if let session = response.session {
                saveSession(session)
                currentUser = response.user
                isAuthenticated = true
            }
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to complete Apple sign-in"
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

    /// Handle OAuth callback with tokens directly (from redirect URL)
    func handleOAuthTokens(accessToken: String, refreshToken: String) async {
        errorMessage = nil

        // Save the tokens
        let session = AuthService.Session(accessToken: accessToken, refreshToken: refreshToken)
        saveSession(session)

        // Fetch current user info
        do {
            let user = try await AuthService.getCurrentUser(accessToken: accessToken)
            currentUser = user
            isAuthenticated = true
        } catch {
            // Tokens are saved, mark as authenticated even if user fetch fails
            isAuthenticated = true
        }
    }

    // MARK: - Password Reset

    func forgotPassword(email: String) async -> Bool {
        errorMessage = nil

        do {
            _ = try await AuthService.forgotPassword(email: email)
            return true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = "Failed to send reset email"
            return false
        }
    }

    func resetPassword(accessToken: String, newPassword: String) async -> Bool {
        errorMessage = nil

        do {
            _ = try await AuthService.resetPassword(accessToken: accessToken, newPassword: newPassword)
            return true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = "Failed to reset password"
            return false
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

    /// Handle session expiration (401 response) - logs out locally without server call
    func handleSessionExpired() {
        clearSession()
        currentUser = nil
        isAuthenticated = false
    }

    /// Attempts to refresh the token and returns whether it succeeded.
    /// Use this for 401 retry logic - only logs out if refresh fails.
    func attemptTokenRefresh() async -> Bool {
        guard let refreshToken = getRefreshToken() else {
            handleSessionExpired()
            return false
        }

        do {
            let response = try await AuthService.refreshSession(refreshToken: refreshToken)

            if let session = response.session {
                saveSession(session)
                currentUser = response.user
                return true
            } else {
                handleSessionExpired()
                return false
            }
        } catch {
            handleSessionExpired()
            return false
        }
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

    // MARK: - API Call with Retry

    /// Executes an authenticated API call with automatic 401 retry.
    /// If the call fails with sessionExpired, attempts to refresh the token and retry once.
    /// - Parameter operation: A closure that performs the API call using the current access token
    /// - Returns: The result of the API call
    /// - Throws: The original error if retry fails, or non-401 errors
    func withAuthRetry<T>(_ operation: @escaping (String) async throws -> T) async throws -> T {
        guard let accessToken = getAccessToken() else {
            handleSessionExpired()
            throw APIError.sessionExpired
        }

        do {
            return try await operation(accessToken)
        } catch APIError.sessionExpired {
            // Attempt to refresh the token
            let refreshed = await attemptTokenRefresh()

            if refreshed, let newAccessToken = getAccessToken() {
                // Retry with new token
                return try await operation(newAccessToken)
            } else {
                // Refresh failed, user is logged out
                throw APIError.sessionExpired
            }
        }
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
