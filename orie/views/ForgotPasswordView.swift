//
//  ForgotPasswordView.swift
//  orie
//
//  Created by Shareef Evans on 09/02/2026.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccessMessage = false

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
                        Text("Reset Password")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Description
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)

                        // MARK: Email
                        AuthTextField(
                            placeholder: "Email",
                            text: $email,
                            isDark: isDark,
                            isSecure: false,
                            icon: "envelope",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        // Divider
                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)

                        // MARK: Error Message
                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // MARK: Success Message
                        if showSuccessMessage {
                            Text("Password reset email sent! Check your inbox.")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // MARK: Send Reset Email Button
                        Button(action: {
                            Task {
                                await handleForgotPassword()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: isDark ? .black : .white))
                                } else {
                                    Text("Send Reset Link")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(isDark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 100))
                        }
                        .disabled(isLoading || !isEmailValid)
                        .opacity(isEmailValid ? 1 : 0.6)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(32)
                    .padding(.horizontal, 16)

                    // MARK: - Back to Login
                    Button(action: {
                        dismiss()
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
        .navigationBarHidden(true)
    }

    // MARK: - Computed Properties

    private var isEmailValid: Bool {
        !email.isEmpty && email.contains("@")
    }

    // MARK: - Actions

    private func handleForgotPassword() async {
        isLoading = true
        showSuccessMessage = false
        defer { isLoading = false }

        let success = await authManager.forgotPassword(email: email)
        if success {
            showSuccessMessage = true
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
