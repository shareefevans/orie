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
    @Published var profileSetupCompleted = false

    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let currentUserKey = "currentUser"
    // Coalesces concurrent token-refresh attempts so only one uses the refresh
    // token at a time (Supabase rotates it on each use — a second concurrent
    // call with the same token would fail and log the user out).
    private var refreshTask: Task<Bool, Never>? = nil

    init() {
        checkAuthState()
    }

    // MARK: - Auth State

    func checkAuthState() {
        isLoading = true

        // If we have a refresh token, try to get a fresh session
        if let _ = getRefreshToken() {
            // Load saved user data immediately for offline scenarios
            currentUser = loadSavedUser()

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
                if let user = response.user {
                    saveUser(user)
                }
                checkProfileSetupCompleted()
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
                if let user = response.user {
                    saveUser(user)
                }
                checkProfileSetupCompleted()
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
                if let user = response.user {
                    saveUser(user)
                }
                checkProfileSetupCompleted()
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
                if let user = response.user {
                    saveUser(user)
                }
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
            saveUser(user)
            checkProfileSetupCompleted()
            isAuthenticated = true
        } catch {
            // Tokens are saved, mark as authenticated even if user fetch fails
            checkProfileSetupCompleted()
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

    // MARK: - Delete Account

    func deleteAccount() async -> Bool {
        errorMessage = nil

        do {
            try await withAuthRetry { accessToken in
                try await AuthService.deleteAccount(accessToken: accessToken)
            }
        } catch APIError.sessionExpired {
            // Already handled by withAuthRetry
            return false
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = "Failed to delete account"
            return false
        }

        clearSession()
        currentUser = nil
        isAuthenticated = false
        return true
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
        // If a refresh is already in flight, wait for it instead of firing a
        // second one with the same (now-consumed) refresh token.
        if let existingTask = refreshTask {
            return await existingTask.value
        }

        let task = Task {
            defer { self.refreshTask = nil }

            guard let refreshToken = self.getRefreshToken() else {
                self.handleSessionExpired()
                return false
            }

            do {
                let response = try await AuthService.refreshSession(refreshToken: refreshToken)
                if let session = response.session {
                    self.saveSession(session)
                    self.currentUser = response.user
                    if let user = response.user {
                        self.saveUser(user)
                    }
                    return true
                } else {
                    self.handleSessionExpired()
                    return false
                }
            } catch {
                self.handleSessionExpired()
                return false
            }
        }

        refreshTask = task
        return await task.value
    }

    // MARK: - Session Management

    private func saveSession(_ session: AuthService.Session) {
        UserDefaults.standard.set(session.accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(session.refreshToken, forKey: refreshTokenKey)
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }

    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    // MARK: - User Data Persistence

    private func saveUser(_ user: AuthService.User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
    }

    private func loadSavedUser() -> AuthService.User? {
        guard let data = UserDefaults.standard.data(forKey: currentUserKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AuthService.User.self, from: data)
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

    // MARK: - Profile Setup

    func markProfileSetupCompleted() {
        guard let userId = currentUser?.id else { return }
        UserDefaults.standard.set(true, forKey: "profileSetup_\(userId)")
        profileSetupCompleted = true
    }

    private func checkProfileSetupCompleted() {
        guard let userId = currentUser?.id else { profileSetupCompleted = false; return }
        profileSetupCompleted = UserDefaults.standard.bool(forKey: "profileSetup_\(userId)")
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
                if let user = response.user {
                    saveUser(user)
                }
                checkProfileSetupCompleted()
                isAuthenticated = true
            } else {
                // Server responded but returned no session — refresh token is invalid
                clearSession()
                isAuthenticated = false
            }
        } catch is AuthError {
            // Server explicitly rejected the refresh token — log out
            clearSession()
            isAuthenticated = false
        } catch {
            // Network or other transient error — preserve the existing session.
            // Don't log out the user just because of connectivity issues.
            if getAccessToken() != nil {
                // Restore user from local storage when offline
                currentUser = loadSavedUser()
                checkProfileSetupCompleted()
                isAuthenticated = true
            }
        }
    }
}
