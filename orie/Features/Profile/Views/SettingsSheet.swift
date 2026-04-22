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

    @State private var showDowngradeModal = false

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
                        isDark: isDark,
                        onUpgradeTapped: { subscriptionManager.showUpgradePaywall = true },
                        onDowngradeTapped: { showDowngradeModal = true }
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
        .overlay {
            if subscriptionManager.showUpgradePaywall {
                UpgradePremiumModal()
                    .transaction { $0.animation = nil }
            } else if showDowngradeModal {
                downgradeModal
                    .transaction { $0.animation = nil }
            }
        }
    }

    // MARK: - Downgrade Modal
    private var downgradeModal: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { showDowngradeModal = false }

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free")
                            .font(.footnote)
                            .fontWeight(.regular)
                            .foregroundColor(Color.secondaryText(isDark))
                        Text("$0usd per month")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.primaryText(isDark))
                    }
                    Spacer()
                }

                Rectangle()
                    .fill(isDark ? Color(red: 24/255, green: 24/255, blue: 24/255) : Color(red: 220/255, green: 220/255, blue: 220/255))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ForEach([
                        "3 Ai entries per day",
                        "Voice to text",
                        "Unlimited manual entries",
                        "Weekly tracking & overview dashboard",
                        "Predictive entries",
                    ], id: \.self) { text in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            Text(text)
                                .font(.system(size: 14))
                                .foregroundColor(Color.primaryText(isDark))
                            Spacer()
                        }
                    }
                }

                Rectangle()
                    .fill(isDark ? Color(red: 24/255, green: 24/255, blue: 24/255) : Color(red: 220/255, green: 220/255, blue: 220/255))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Buttons
                HStack(spacing: 12) {
                    Button(action: { showDowngradeModal = false }) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isDark ? .white : .black)
                            .padding(.horizontal, 20)
                            .frame(height: 50)
                    }
                    .glassEffect(in: .capsule)
                    .disabled(subscriptionManager.isLoading)

                    Button(action: {
                        Task {
                            let userId = authManager.currentUser?.id ?? ""
                            await subscriptionManager.selectFree(authManager: authManager, userId: userId)
                            showDowngradeModal = false
                        }
                    }) {
                        ZStack {
                            Text("Downgrade to Free")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(isDark ? .white : .black)
                                .opacity(subscriptionManager.isLoading ? 0 : 1)

                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: isDark ? .white : .black))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .glassEffect(in: .capsule)
                    .disabled(subscriptionManager.isLoading)
                }
            }
            .padding(24)
            .background(Color.cardBackground(isDark))
            .cornerRadius(32)
            .padding(.horizontal, 16)
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
