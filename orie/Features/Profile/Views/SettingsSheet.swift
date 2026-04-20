//
//  SettingsSheet.swift
//  orie
//

import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    VStack(alignment: .center, spacing: 4) {
                        Text("App Settings")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primaryText(isDark))
                        Text("Configure Orie")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    SettingsTabContent(
                        isLoading: false,
                        isDark: isDark
                    )
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground(isDark))
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .presentationDragIndicator(.visible)
        .onAppear {
            Task { await subscriptionManager.loadStatus(authManager: authManager) }
        }
    }
}

#Preview {
    SettingsSheet()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(LocalNotificationManager.shared)
        .environmentObject(SubscriptionManager())
}
