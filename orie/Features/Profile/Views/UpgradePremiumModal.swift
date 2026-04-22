//
//  UpgradePremiumModal.swift
//  orie
//

import SwiftUI

struct UpgradePremiumModal: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var themeManager: ThemeManager

    var isDark: Bool { themeManager.isDarkMode }

    private func dismiss() {
        subscriptionManager.showUpgradePaywall = false
        subscriptionManager.paywallMessage = ""
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium")
                            .font(.footnote)
                            .fontWeight(.regular)
                            .foregroundColor(.yellow)
                        Text("$2.99usd per month")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.primaryText(isDark))
                        if !subscriptionManager.paywallMessage.isEmpty {
                            Text(subscriptionManager.paywallMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Text("Upgrade")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.yellow.opacity(0.55), in: Capsule())
                        .glassEffect(in: Capsule())
                }

                Rectangle()
                    .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ForEach([
                        "15 Ai entries per day",
                        "Orie natural language nutritional chatbot",
                        "Voice to Text",
                        "Unlimited photo scanning",
                        "Unlimited manual entries",
                        "Weekly Tracking & Overview Dashboard",
                        "Predictive Entries",
                    ], id: \.self) { text in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                                .frame(width: 20)
                            Text(text)
                                .font(.system(size: 14))
                                .foregroundColor(Color.primaryText(isDark))
                            Spacer()
                        }
                    }
                }

                Rectangle()
                    .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                Text("This is a monthly, recurring payment that can be canceled at any time")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)

                Rectangle()
                    .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Buttons
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
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
                            await subscriptionManager.selectPremium(authManager: authManager, userId: userId)
                            dismiss()
                        }
                    }) {
                        ZStack {
                            Text("Upgrade Plan")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.black)
                                .opacity(subscriptionManager.isLoading ? 0 : 1)

                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.yellow.opacity(0.55), in: .capsule)
                    }
                    .glassEffect(in: .capsule)
                    .disabled(subscriptionManager.isLoading)
                }
            }
            .padding(24)
            .background(Color.cardBackground(isDark))
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.6), Color.yellow.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal, 16)
        }
        .onAppear {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
