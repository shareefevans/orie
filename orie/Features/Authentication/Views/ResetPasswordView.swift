//
//  ResetPasswordView.swift
//  orie
//
//  Created by Shareef Evans on 09/02/2026.
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showResetPassword: Bool

    let accessToken: String

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var localErrorMessage: String?

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        ZStack {
            // MARK: - Background
            Color.appBackground(isDark)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // MARK: - Logo/Title
                    Image("AppLogoText")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .padding(.bottom, -36)

                    // MARK: - Form Card
                    VStack(spacing: 16) {
                        // Title
                        Text("Enter New Password")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Description
                        Text("Please enter your new password below.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)

                        // MARK: New Password
                        AuthTextField(
                            placeholder: "New Password",
                            text: $newPassword,
                            isDark: isDark,
                            isSecure: true
                        )

                        // Divider
                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)

                        // MARK: Confirm Password
                        AuthTextField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            isDark: isDark,
                            isSecure: true
                        )

                        // MARK: Error Message
                        if let error = localErrorMessage ?? authManager.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // MARK: Success Message
                        if showSuccessMessage {
                            Text("Password updated successfully!")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // MARK: Reset Password Button
                        Button(action: {
                            Task {
                                await handleResetPassword()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: isDark ? .black : .white))
                                } else {
                                    Text("Update Password")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(isDark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 100))
                        }
                        .disabled(isLoading || !isFormValid || showSuccessMessage)
                        .opacity(isFormValid && !showSuccessMessage ? 1 : 0.6)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(32)
                    .padding(.horizontal, 16)

                    // MARK: - Back to Login Button
                    Button(action: {
                        showResetPassword = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14))

                            Text("Back to Login")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color.primaryText(isDark))
                    }
                    .padding(.top, 16)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    // MARK: - Actions

    private func handleResetPassword() async {
        localErrorMessage = nil

        // Validate passwords match
        if newPassword != confirmPassword {
            localErrorMessage = "Passwords do not match"
            return
        }

        // Validate password length
        if newPassword.count < 6 {
            localErrorMessage = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        defer { isLoading = false }

        let success = await authManager.resetPassword(accessToken: accessToken, newPassword: newPassword)
        if success {
            showSuccessMessage = true
            // Auto-dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showResetPassword = false
            }
        }
    }
}

#Preview {
    ResetPasswordView(showResetPassword: .constant(true), accessToken: "test-token")
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
