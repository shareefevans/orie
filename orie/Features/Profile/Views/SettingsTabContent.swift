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

    var onUpgradeTapped: (() -> Void)? = nil
    var onDowngradeTapped: (() -> Void)? = nil

    @State private var showNotificationDeniedAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteErrorAlert = false
    @State private var isDeletingAccount = false
    @AppStorage("calorieProgressActivityEnabled") private var calorieProgressActivityEnabled = true

    var body: some View {
        Group {
            if isLoading {
                ProfileSheetSkeleton(isDark: isDark, tab: .settings)
            } else {
                subscriptionCard
                aiEntriesCard
                appCard
                deleteAccountButton
            }
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
                    isDeletingAccount = true
                    let success = await authManager.deleteAccount()
                    isDeletingAccount = false
                    if success {
                        dismiss()
                    } else {
                        showDeleteErrorAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Failed to Delete Account", isPresented: $showDeleteErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "Something went wrong. Please try again.")
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
                    HStack(spacing: 8) {
                        Text(subscriptionManager.tier == .premium ? "Premium Plan" : "Free Plan")
                            .font(.system(size: 18, weight: .semibold))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primaryText(isDark))
                        if subscriptionManager.tier == .premium {
                            Text("Popular")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.yellow.opacity(0.55), in: Capsule())
                                .glassEffect(in: Capsule())
                        }
                    }
                }
                Spacer()
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

            Rectangle()
                .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                .frame(height: 1)

            if subscriptionManager.tier == .premium {
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
            }

            // CTA
            if subscriptionManager.tier == .premium {
                Button(action: { onDowngradeTapped?() }) {
                    Text("Downgrade Plan")
                        .font(.system(size: 14, weight: .semibold))
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

    // MARK: - AI Entries Card
    private var aiEntriesCard: some View {
        let limit = subscriptionManager.aiLimit > 0 ? subscriptionManager.aiLimit : (subscriptionManager.tier == .premium ? 15 : 3)
        let used = subscriptionManager.aiUsedToday

        return VStack(alignment: .leading, spacing: 8) {
            Text("Ai Entries")
                .font(.system(size: 13))
                .foregroundColor(.gray)

            HStack(spacing: 8) {
                Text("Entries Used")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))

                Text("\(used) / \(limit) Ai Entries")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(in: Capsule())
            }

            let columns = Array(repeating: GridItem(.flexible()), count: 10)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<limit, id: \.self) { index in
                    if index < used {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray.opacity(0.4))
                    }
                }
            }

            if subscriptionManager.tier != .premium {
                Rectangle()
                    .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                    .frame(height: 1)
                    .padding(.top, 8)
                Text("Upgrade to Premium to increase your total Ai entries to 15 per day")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(Color.secondaryText(isDark))
                    .padding(.top, 8)
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
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .frame(width: 20)
                    Text(feature)
                        .font(.system(size: 14))
                        .foregroundColor(Color.primaryText(isDark))
                    Spacer()
                }
            }
        }
    }

    private var freeFeaturesList: some View {
        let features = [
            "3 Ai entries per day",
            "Voice to text",
            "Unlimited manual entries",
            "Weekly tracking & overview dashboard",
            "Predictive entries",
        ]
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    Text(feature)
                        .font(.system(size: 14))
                        .foregroundColor(Color.primaryText(isDark))
                    Spacer()
                }
            }
        }
    }

    // MARK: - Upgrade Content
    private var upgradeContent: some View {
        Button(action: { onUpgradeTapped?() }) {
            HStack(spacing: 8) {
                Text("Upgrade to Premium")
                    .font(.system(size: 14, weight: .semibold))
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
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Personalise Orie")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))
                Text("Configure Orie to suit your needs")
                    .font(.footnote)
                    .foregroundColor(Color.secondaryText(isDark))
            }
            .padding(.bottom, 16)
            Rectangle().fill(Color(red: 24/255, green: 24/255, blue: 24/255)).frame(height: 1)
            appToggles
            Rectangle().fill(Color(red: 24/255, green: 24/255, blue: 24/255)).frame(height: 1)
            accountActions
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
    }

    // MARK: - App Toggles
    private var appToggles: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sun.lefthalf.filled")
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
                Text("Dark Mode")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                Toggle("", isOn: $themeManager.isDarkMode).labelsHidden().disabled(true)
            }
            .padding(.vertical, 8)
            Rectangle().fill(Color(red: 24/255, green: 24/255, blue: 24/255)).frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "bell")
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
                Text("Meal Reminders")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                Toggle("", isOn: notificationsBinding).labelsHidden()
            }
            .padding(.vertical, 8)
            Rectangle().fill(Color(red: 24/255, green: 24/255, blue: 24/255)).frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
                Text("Dynamic Island")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                Toggle("", isOn: calorieProgressBinding).labelsHidden()
            }
            .padding(.vertical, 8)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Account Actions
    private var accountActions: some View {
        Button(action: { Task { await authManager.logout(); dismiss() } }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
                Text("Log Out")
                    .font(.footnote)
                    .foregroundColor(Color.primaryText(isDark))
                    .fontWeight(.medium)
                Spacer()
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Delete Account Button
    private var deleteAccountButton: some View {
        Button(action: { showDeleteAccountAlert = true }) {
            HStack(spacing: 10) {
                if isDeletingAccount {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                Text(isDeletingAccount ? "Deleting..." : "Delete Account")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.25), in: Capsule())
        }
        .glassEffect(in: .capsule)
        .disabled(isDeletingAccount)
        .padding(.top, 8)
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

#Preview("Free Plan") {
    ScrollView {
        VStack(spacing: 16) {
            SettingsTabContent(isLoading: false, isDark: true)
        }
        .padding()
    }
    .background(Color.black)
    .environmentObject(AuthManager())
    .environmentObject(ThemeManager())
    .environmentObject(LocalNotificationManager.shared)
    .environmentObject(SubscriptionManager())
}

#Preview("Premium Plan") {
    let sub = SubscriptionManager()
    sub.tier = .premium
    sub.aiLimit = 15
    sub.aiUsedToday = 4
    return ScrollView {
        VStack(spacing: 16) {
            SettingsTabContent(isLoading: false, isDark: true)
        }
        .padding()
    }
    .background(Color.black)
    .environmentObject(AuthManager())
    .environmentObject(ThemeManager())
    .environmentObject(LocalNotificationManager.shared)
    .environmentObject(sub)
}
