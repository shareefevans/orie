//
//  LoginView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showOAuthSheet = false
    @State private var oauthURL: URL?

    var body: some View {
        ZStack {
            // Background
            Color(red: 247/255, green: 247/255, blue: 247/255)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)

                    // Logo/Title
                    VStack(spacing: 8) {
                        Text("orie")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(red: 69/255, green: 69/255, blue: 69/255))

                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 32)

                    // Form Card
                    VStack(spacing: 16) {
                        // Full Name (Sign Up only)
                        if isSignUp {
                            AuthTextField(
                                placeholder: "Full Name",
                                text: $fullName,
                                isSecure: false
                            )
                        }

                        // Email
                        AuthTextField(
                            placeholder: "Email",
                            text: $email,
                            isSecure: false,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        // Password
                        AuthTextField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )

                        // Error Message
                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Primary Button
                        Button(action: {
                            Task {
                                await handleAuth()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Log In")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
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
                    .background(Color.white)
                    .cornerRadius(32)
                    .padding(.horizontal, 16)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)

                        Text("or")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    // Social Login Buttons
                    VStack(spacing: 12) {
                        // Google Sign In
                        SocialLoginButton(
                            title: "Continue with Google",
                            icon: "g.circle.fill",
                            backgroundColor: Color.white,
                            textColor: .black
                        ) {
                            Task {
                                await handleGoogleSignIn()
                            }
                        }

                        // Apple Sign In
                        SocialLoginButton(
                            title: "Continue with Apple",
                            icon: "apple.logo",
                            backgroundColor: Color.black,
                            textColor: .white
                        ) {
                            Task {
                                await handleAppleSignIn()
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Toggle Sign Up / Log In
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp.toggle()
                            authManager.errorMessage = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.gray)

                            Text(isSignUp ? "Log In" : "Sign Up")
                                .foregroundColor(Color(red: 69/255, green: 69/255, blue: 69/255))
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

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6

        if isSignUp {
            return emailValid && passwordValid && !fullName.isEmpty
        }
        return emailValid && passwordValid
    }

    // MARK: - Actions

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

// MARK: - Auth Text Field

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @State private var isPasswordVisible = false

    var body: some View {
        HStack {
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }

            if isSecure {
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(red: 247/255, green: 247/255, blue: 247/255))
        .cornerRadius(16)
    }
}

// MARK: - Social Login Button

struct SocialLoginButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.gray.opacity(0.2), lineWidth: backgroundColor == .white ? 1 : 0)
            )
        }
    }
}

// MARK: - OAuth WebView

import WebKit

struct OAuthWebView: UIViewRepresentable {
    let url: URL
    let onCodeReceived: (String) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeReceived: onCodeReceived)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onCodeReceived: (String) -> Void

        init(onCodeReceived: @escaping (String) -> Void) {
            self.onCodeReceived = onCodeReceived
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                onCodeReceived(code)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
