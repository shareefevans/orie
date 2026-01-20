//
//  orieApp.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

@main
struct orieApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    // Splash/Loading screen
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
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .environmentObject(themeManager)
                }
            }
        }
    }
}
