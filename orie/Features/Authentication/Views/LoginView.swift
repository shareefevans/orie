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

    @Binding var showResetPassword: Bool
    @Binding var resetPasswordToken: String

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var appleSignInHelper = AppleSignInHelper()
    @State private var showForgotPassword = false

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        ZStack {
            // MARK: - ❇️ Background
            Color.appBackground(isDark)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // MARK: - ❇️ Logo/Title
                    Image("AppLogoText")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .padding(.bottom, -36)

                    // MARK: - ❇️ Form Card
                    VStack(spacing: 16) {
                        // MARK: 👉 Full Name (Sign Up only)
                        if isSignUp {
                            AuthTextField(
                                placeholder: "Full Name",
                                text: $fullName,
                                isDark: isDark,
                                isSecure: false,
                                icon: "person.circle"
                            )

                            // Divider
                            Rectangle()
                                .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                                .frame(height: 1)
                        }

                        // MARK: 👉 Email
                        AuthTextField(
                            placeholder: "Email",
                            text: $email,
                            isDark: isDark,
                            isSecure: false,
                            icon: "person.circle",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        // Divider
                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)

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
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Log In")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.accessibleYellow(isDark).opacity(0.55), in: .capsule)
                        }
                        .glassEffect(in: .capsule)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(32)
                    .padding(.horizontal, 16)

                    // MARK: 👉 Forgot Password (Login only)
                    if !isSignUp {
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isDark ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .glassEffect(in: .capsule)
                        .padding(.horizontal, 16)
                        .padding(.top, -12)
                    }

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
                    Button(action: { handleAppleSignIn() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(isDark ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .glassEffect(in: .capsule)
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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
        }
        .fullScreenCover(isPresented: $showResetPassword) {
            ResetPasswordView(showResetPassword: $showResetPassword, accessToken: resetPasswordToken)
                .environmentObject(authManager)
                .environmentObject(themeManager)
        }
        .onChange(of: showResetPassword) { _, shouldShow in
            if shouldShow && showForgotPassword {
                // Dismiss forgot password sheet first, then show reset password after delay
                showForgotPassword = false
                showResetPassword = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showResetPassword = true
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
        guard let urlString = await authManager.getGoogleOAuthURL(),
              let url = URL(string: urlString) else {
            return
        }

        OAuthHelper.startOAuth(
            url: url,
            onCodeReceived: { code in
                Task {
                    await authManager.handleOAuthCallback(code: code)
                }
            },
            onTokensReceived: { accessToken, refreshToken in
                Task {
                    await authManager.handleOAuthTokens(accessToken: accessToken, refreshToken: refreshToken)
                }
            },
            onError: { error in
                if let error = error {
                    print("OAuth error: \(error)")
                }
            }
        )
    }

    private func handleAppleSignIn() {
        appleSignInHelper.startSignIn { identityToken, email, fullName in
            Task {
                await authManager.signInWithApple(
                    identityToken: identityToken,
                    fullName: fullName,
                    email: email
                )
            }
        } onError: { error in
            if let error = error {
                print("Apple Sign-In error: \(error)")
            }
        }
    }
}

#Preview {
    LoginView(showResetPassword: .constant(false), resetPasswordToken: .constant(""))
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
