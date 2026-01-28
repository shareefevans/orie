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
        }
    }
}
