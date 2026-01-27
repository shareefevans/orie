//
//  LoginView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showOAuthSheet = false
    @State private var oauthURL: URL?

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        ZStack {
            // MARK: - ❇️ Background
            Color.appBackground(isDark)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)

                    // MARK: - ❇️ Logo/Title
                    VStack(spacing: 8) {
                        Text("orie")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color.primaryText(isDark))

                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.system(size: 16))
                            .foregroundColor(Color.secondaryText(isDark))
                    }
                    .padding(.bottom, 32)

                    // MARK: - ❇️ Form Card
                    VStack(spacing: 16) {
                        // MARK: 👉 Full Name (Sign Up only)
                        if isSignUp {
                            AuthTextField(
                                placeholder: "Full Name",
                                text: $fullName,
                                isDark: isDark,
                                isSecure: false
                            )
                        }

                        // MARK: 👉 Email
                        AuthTextField(
                            placeholder: "Email",
                            text: $email,
                            isDark: isDark,
                            isSecure: false,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        // MARK: 👉 Password
                        AuthTextField(
                            placeholder: "Password",
                            text: $password,
                            isDark: isDark,
                            isSecure: true
                        )

                        // MARK: 🚨 Error Message
                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // MARK: 👉 Primary Button
                        Button(action: {
                            Task {
                                await handleAuth()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: isDark ? .black : .white))
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Log In")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(isDark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 100))
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(32)
                    .padding(.horizontal, 16)

                    // MARK: 👉 Divider
                    HStack {
                        Rectangle()
                            .fill(Color.secondaryText(isDark).opacity(0.3))
                            .frame(height: 1)

                        Text("or")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText(isDark))
                            .padding(.horizontal, 16)

                        Rectangle()
                            .fill(Color.secondaryText(isDark).opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    // MARK: - ❇️ Social Login Buttons
                    VStack(spacing: 12) {
                        // Google Sign In
                        SocialLoginButton(
                            title: "Continue with Google",
                            icon: "g.circle.fill",
                            backgroundColor: Color.cardBackground(isDark),
                            textColor: Color.primaryText(isDark)
                        ) {
                            Task {
                                await handleGoogleSignIn()
                            }
                        }

                        // Apple Sign In
                        SocialLoginButton(
                            title: "Continue with Apple",
                            icon: "apple.logo",
                            backgroundColor: isDark ? Color.white : Color.black,
                            textColor: isDark ? .black : .white
                        ) {
                            Task {
                                await handleAppleSignIn()
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: - ❇️ Toggle Sign Up / Log In
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp.toggle()
                            authManager.errorMessage = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(Color.secondaryText(isDark))

                            Text(isSignUp ? "Log In" : "Sign Up")
                                .foregroundColor(Color.primaryText(isDark))
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }
                    .padding(.top, 16)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showOAuthSheet) {
            if let url = oauthURL {
                OAuthWebView(url: url) { code in
                    showOAuthSheet = false
                    Task {
                        await authManager.handleOAuthCallback(code: code)
                    }
                }
            }
        }
    }

    // MARK: - ❇️ Computed Properties

    private var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6

        if isSignUp {
            return emailValid && passwordValid && !fullName.isEmpty
        }
        return emailValid && passwordValid
    }

    // MARK: - ❇️ Actions

    private func handleAuth() async {
        isLoading = true
        defer { isLoading = false }

        if isSignUp {
            await authManager.signUp(email: email, password: password, fullName: fullName)
        } else {
            await authManager.login(email: email, password: password)
        }
    }

    private func handleGoogleSignIn() async {
        if let urlString = await authManager.getGoogleOAuthURL(),
           let url = URL(string: urlString) {
            oauthURL = url
            showOAuthSheet = true
        }
    }

    private func handleAppleSignIn() async {
        if let urlString = await authManager.getAppleOAuthURL(),
           let url = URL(string: urlString) {
            oauthURL = url
            showOAuthSheet = true
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
