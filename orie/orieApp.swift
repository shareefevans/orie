//
//  orieApp.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - ❇️ Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 👉 Show banner and play sound even when app is open
        completionHandler([.banner, .sound])
    }

    // MARK: - ❇️ Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 👉 Handle the notification tap here if needed
        let userInfo = response.notification.request.content.userInfo
        if let entryId = userInfo["entryId"] as? String {
            print("User tapped notification for entry: \(entryId)")
            // 👉 You can post a notification or update state to navigate to the entry
        }
        completionHandler()
    }
}

@main
struct orieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var authManager = AuthManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var notificationManager = NotificationManager()

    @State private var showResetPassword = false
    @State private var resetPasswordToken: String = ""

    private var localNotificationManager: LocalNotificationManager { LocalNotificationManager.shared }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    // MARK: 👉 Splash/Loading screen
                    ZStack {
                        Color.appBackground(themeManager.isDarkMode)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            Text("orie")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color.primaryText(themeManager.isDarkMode))

                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                } else if authManager.isAuthenticated {
                    MainView()
                        .environmentObject(authManager)
                        .environmentObject(themeManager)
                        .environmentObject(notificationManager)
                        .environmentObject(localNotificationManager)
                        .onAppear {
                            // MARK: 👉 Sync notifications when app opens
                            Task {
                                await notificationManager.syncSystemNotifications()
                            }
                        }
                } else {
                    LoginView(
                        showResetPassword: $showResetPassword,
                        resetPasswordToken: $resetPasswordToken
                    )
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                }
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && authManager.isAuthenticated {
                    // Refresh session when app becomes active to prevent stale tokens
                    Task {
                        await authManager.refreshSession()
                    }
                }
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "orie",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        let queryItems = components.queryItems ?? []

        // Handle OAuth callback: orie://callback?access_token=...&refresh_token=...
        if url.host == "callback" {
            let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value
            let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value

            if let accessToken = accessToken, let refreshToken = refreshToken {
                Task {
                    await authManager.handleOAuthTokens(accessToken: accessToken, refreshToken: refreshToken)
                }
            }
        }

        // Handle password reset: orie://reset-password#access_token=...&type=recovery
        // Supabase sends tokens in the URL fragment, not query params
        if url.host == "reset-password" {
            // Try query params first
            if let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value {
                resetPasswordToken = accessToken
                showResetPassword = true
                return
            }

            // Try fragment (Supabase format)
            if let fragment = url.fragment {
                let fragmentItems = fragment.components(separatedBy: "&")
                    .compactMap { item -> (String, String)? in
                        let parts = item.components(separatedBy: "=")
                        guard parts.count == 2 else { return nil }
                        return (parts[0], parts[1])
                    }
                    .reduce(into: [String: String]()) { $0[$1.0] = $1.1 }

                if let accessToken = fragmentItems["access_token"] {
                    resetPasswordToken = accessToken
                    showResetPassword = true
                }
            }
        }
    }
}
