//
//  SettingsTabContent.swift
//  orie
//

import SwiftUI

struct SettingsTabContent: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let isLoading: Bool
    let isDark: Bool
    var onFeedback: () -> Void

    @State private var showNotificationDeniedAlert = false
    @State private var showDeleteAccountAlert = false
    @AppStorage("calorieProgressActivityEnabled") private var calorieProgressActivityEnabled = true

    var body: some View {
        Group {
            if isLoading {
                ProfileSheetSkeleton(isDark: isDark, tab: .settings)
            } else {
                subscriptionCard
                appCard
            }
            feedbackButton
        }
        .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive meal reminders, please enable notifications in Settings.")
        }
        .alert("Are you sure you want to delete your account?", isPresented: $showDeleteAccountAlert) {
            Button("Yes", role: .destructive) {
                Task {
                    let success = await authManager.deleteAccount()
                    if success { dismiss() }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Subscription Card
    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text(subscriptionManager.tier == .premium ? "Premium Plan" : "Free Plan")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))
                }
                Spacer()
                if subscriptionManager.tier == .premium {
                    Text("Popular")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.yellow.opacity(0.55), in: Capsule())
                        .glassEffect(in: Capsule())
                }
            }

            Rectangle()
                .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                .frame(height: 1)

            // Features
            if subscriptionManager.tier == .premium {
                premiumFeaturesList
            } else {
                freeFeaturesList
            }

            // AI usage
            if subscriptionManager.aiLimit > 0 {
                Text("AI: \(subscriptionManager.aiUsedToday)/\(subscriptionManager.aiLimit) queries used today")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // Disclaimer
            Text("This is a monthly, recurring payment that can be canceled at any time")
                .font(.system(size: 12))
                .italic()
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // CTA
            if subscriptionManager.tier == .premium {
                Button(action: {
                    Task {
                        let userId = authManager.currentUser?.id ?? ""
                        await subscriptionManager.selectFree(authManager: authManager, userId: userId)
                    }
                }) {
                    Text("Downgrade Plan")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isDark ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .glassEffect(in: .capsule)
                .disabled(subscriptionManager.isLoading)
            } else {
                upgradeContent
            }
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
    }

    private var premiumFeaturesList: some View {
        let features = [
            "15 Ai entries per day",
            "Orie natural language nutritional chatbot",
            "Voice to text",
            "Unlimited photo scanning",
            "Unlimited manual entries",
            "Weekly tracking & overview dashboard",
            "Predictive entries",
        ]
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow)
                    Text(feature)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                }
            }
        }
    }

    private var freeFeaturesList: some View {
        let features = [
            "3 Ai entries per day",
            "Unlimited manual entries",
            "Full dashboard & tracking",
            "Predictive entries",
        ]
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.secondaryText(isDark))
                    Text(feature)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                }
            }
        }
    }

    // MARK: - Upgrade Content
    private var upgradeContent: some View {
        Button(action: {
            Task {
                let userId = authManager.currentUser?.id ?? ""
                await subscriptionManager.selectPremium(authManager: authManager, userId: userId)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                Text("Upgrade to Premium · $2.99/mo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accessibleYellow(isDark).opacity(0.55), in: .capsule)
        }
        .glassEffect(in: .capsule)
        .disabled(subscriptionManager.isLoading)
    }

    private var premiumInclusionsList: some View {
        let items: [(String, String)] = [
            ("sparkles", "Ask Orie AI chat assistant"),
            ("photo.on.rectangle.angled", "AI food image recognition"),
            ("fork.knife", "Smart nutrition lookup"),
            ("15.circle", "15 AI queries per day"),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Premium inclusions")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(Color.primaryText(isDark))
            ForEach(items, id: \.0) { icon, label in
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.footnote)
                        .foregroundColor(.yellow)
                        .frame(width: 16)
                    Text(label)
                        .font(.footnote)
                        .foregroundColor(Color.secondaryText(isDark))
                }
            }
        }
    }

    // MARK: - App Card
    private var appCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "app.background.dotted")
                        .font(.title3)
                        .foregroundColor(Color.primaryText(isDark))
                    Text("App")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))
                }
                Text("Manage your app settings.")
                    .font(.footnote)
                    .foregroundColor(Color.secondaryText(isDark))
            }
            .padding(.bottom, 8)
            Divider()
            appToggles
            Divider()
            accountActions
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
    }

    // MARK: - App Toggles
    private var appToggles: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Location")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                Toggle("", isOn: .constant(true)).labelsHidden()
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meal Reminders")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primaryText(isDark))
                    Text("Get notified at scheduled meal times")
                        .font(.caption2)
                        .foregroundColor(Color.secondaryText(isDark))
                }
                Spacer()
                Toggle("", isOn: notificationsBinding).labelsHidden()
            }
            Divider()
            HStack {
                Text("Dark Mode")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                Toggle("", isOn: $themeManager.isDarkMode).labelsHidden()
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calorie Progress")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primaryText(isDark))
                    Text("Show all-day tracker in Dynamic Island")
                        .font(.caption2)
                        .foregroundColor(Color.secondaryText(isDark))
                }
                Spacer()
                Toggle("", isOn: calorieProgressBinding).labelsHidden()
            }
        }
    }

    // MARK: - Account Actions
    private var accountActions: some View {
        VStack(spacing: 0) {
            Button(action: { Task { await authManager.logout(); dismiss() } }) {
                HStack {
                    Text("Log Out")
                        .font(.footnote)
                        .foregroundColor(Color.primaryText(isDark))
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(Color.iconColor(isDark))
                }
            }
            Divider()
            Button(action: { showDeleteAccountAlert = true }) {
                HStack {
                    Text("Delete Account")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "trash").foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Feedback Button
    private var feedbackButton: some View {
        Button(action: onFeedback) {
            Text("Feedback")
                .font(.system(size: 12))
                .fontWeight(.medium)
                .foregroundColor(Color.primaryText(isDark))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .glassEffect(.regular.interactive())
    }

    // MARK: - Bindings
    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { localNotificationManager.notificationsEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let granted = await localNotificationManager.requestAuthorization()
                        if granted { localNotificationManager.notificationsEnabled = true }
                        else { showNotificationDeniedAlert = true }
                    }
                } else {
                    localNotificationManager.notificationsEnabled = false
                }
            }
        )
    }

    private var calorieProgressBinding: Binding<Bool> {
        Binding(
            get: { calorieProgressActivityEnabled },
            set: { newValue in
                calorieProgressActivityEnabled = newValue
                if !newValue {
                    if #available(iOS 16.1, *) {
                        CalorieProgressActivityManager.shared.endCalorieTracking()
                    }
                }
            }
        )
    }
}

#Preview {
    SettingsTabContent(isLoading: false, isDark: true, onFeedback: {})
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(LocalNotificationManager.shared)
        .environmentObject(SubscriptionManager())
        .padding()
        .background(Color.black)
}
