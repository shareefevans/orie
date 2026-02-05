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
                    LoginView()
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
        // Handle OAuth callback: orie://callback?access_token=...&refresh_token=...
        guard url.scheme == "orie",
              url.host == "callback",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return
        }

        let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value
        let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value

        if let accessToken = accessToken, let refreshToken = refreshToken {
            Task {
                await authManager.handleOAuthTokens(accessToken: accessToken, refreshToken: refreshToken)
            }
        }
    }
}
