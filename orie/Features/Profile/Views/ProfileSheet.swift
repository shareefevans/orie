//
//  ProfileSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

enum ProfileTab {
    case profile, settings
}

struct ProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var startTab: ProfileTab = .profile

    // MARK: - ❇️ User data
    @State private var userName = ""
    @State private var dailyCalories = 0
    @State private var dailyProtein = 0
    @State private var dailyCarbs = 0
    @State private var dailyFats = 0
    @State private var dailySodium = 0
    @State private var dailyFibre = 0
    @State private var dailySugar = 0
    @State private var isLoading = true

    // MARK: - ❇️ Personal data
    @State private var age = 0
    @State private var weight = 0
    @State private var height = 0
    @State private var bodyFat = 0
    @State private var gender = ""

    // MARK: - ❇️ Settings
    @State private var selectedTab: ProfileTab = .profile
    @State private var locationEnabled = true
    @State private var showNotificationDeniedAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showFeedbackModal = false
    @State private var feedbackText = ""
    @State private var isSendingFeedback = false
    @State private var showFeedbackSentAlert = false
    @AppStorage("calorieProgressActivityEnabled") private var calorieProgressActivityEnabled = true

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    headerView
//                    tabPickerView
                    if selectedTab == .profile { profileTabContent }
                    if selectedTab == .settings { settingsTabContent }
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
            selectedTab = startTab
            loadProfile()
            Task { await subscriptionManager.loadStatus(authManager: authManager) }
        }
        .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
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
                    if success {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Feedback Sent", isPresented: $showFeedbackSentAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thank you for your feedback!")
        }
        .sheet(isPresented: $showFeedbackModal) {
            NavigationView {
                Form {
                    Section {
                        ZStack(alignment: .topLeading) {
                            if feedbackText.isEmpty {
                                Text("Your feedback")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $feedbackText)
                                .frame(minHeight: 120)
                        }
                    }
                }
                .navigationTitle("Send Feedback")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showFeedbackModal = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isSendingFeedback {
                            ProgressView()
                        } else {
                            Button("Send") {
                                sendFeedback()
                            }
                            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }


    // MARK: - ❇️ Subviews

    @ViewBuilder private var headerView: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(userName.isEmpty ? "User logged Out" : userName)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(Color.primaryText(isDark))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

//    @ViewBuilder private var tabPickerView: some View {
//        Picker("Tab", selection: $selectedTab) {
//            Text("Profile").tag(ProfileTab.profile)
//            Text("Settings").tag(ProfileTab.settings)
//        }
//        .pickerStyle(.segmented)
//        .padding(.bottom, 4)
//    }

    @ViewBuilder private var profileTabContent: some View {
        if isLoading {
            ProfileSheetSkeleton(isDark: isDark, tab: .profile)
        } else {
            bodyCard
            macrosCard
        }
        Button(action: { feedbackText = ""; showFeedbackModal = true }) {
            Text("Feedback")
                .font(.system(size: 12))
                .fontWeight(.medium)
                .foregroundColor(Color.primaryText(isDark))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .glassEffect(.regular.interactive())
    }

    @ViewBuilder private var bodyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.mind.and.body.circle")
                        .font(.title3)
                        .foregroundColor(Color.primaryText(isDark))
                    Text("Body")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))
                }
                Text("Set up your body composition below.")
                    .font(.footnote)
                    .foregroundColor(Color.secondaryText(isDark))
            }
            .padding(.bottom, 8)
            Divider()
            MacroRow(label: "Age", value: $age, unit: "yrs", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Weight", value: $weight, unit: "kg", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Height", value: $height, unit: "cm", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Body Fat", value: $bodyFat, unit: "%", isDark: isDark, onSave: saveProfile)
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(24)
    }

    @ViewBuilder private var macrosCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle")
                        .font(.title3)
                        .foregroundColor(Color.primaryText(isDark))
                    Text("Macros")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))
                }
                Text("Set your daily calorie and macro goals.")
                    .font(.footnote)
                    .foregroundColor(Color.secondaryText(isDark))
            }
            .padding(.bottom, 8)
            Divider()
            MacroRow(label: "Calories", value: $dailyCalories, unit: "c", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Protein", value: $dailyProtein, unit: "g", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Carbohydrates", value: $dailyCarbs, unit: "g", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Fats", value: $dailyFats, unit: "g", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Sodium", value: $dailySodium, unit: "mg", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Fibre", value: $dailyFibre, unit: "g", isDark: isDark, onSave: saveProfile)
            Divider()
            MacroRow(label: "Sugar", value: $dailySugar, unit: "g", isDark: isDark, onSave: saveProfile)
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(24)
    }

    @ViewBuilder private var settingsTabContent: some View {
        if isLoading {
            ProfileSheetSkeleton(isDark: isDark, tab: .settings)
        } else {
            subscriptionCard
            appCard
        }
        Button(action: { feedbackText = ""; showFeedbackModal = true }) {
            Text("Feedback")
                .font(.system(size: 12))
                .fontWeight(.medium)
                .foregroundColor(Color.primaryText(isDark))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .glassEffect(.regular.interactive())
    }

    private var upgradeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium pricing")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(Color.primaryText(isDark))
            Text("$2.99 USD / mth")
                .font(.footnote)
                .foregroundColor(.yellow)
            Button(action: {
                Task {
                    let userId = authManager.currentUser?.id ?? ""
                    await subscriptionManager.selectPremium(authManager: authManager, userId: userId)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.black)
                    Text("Upgrade to Premium")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.accessibleYellow(isDark).opacity(0.55), in: RoundedRectangle(cornerRadius: 20))
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
            }
            .disabled(subscriptionManager.isLoading)
            VStack(alignment: .leading, spacing: 10) {
                Text("Premium inclusions")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryText(isDark))
                ForEach([
                    ("sparkles", "Ask Orie AI chat assistant"),
                    ("photo.on.rectangle.angled", "AI food image recognition"),
                    ("fork.knife", "Smart nutrition lookup"),
                    ("15.circle", "15 AI queries per day"),
                ], id: \.0) { icon, label in
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
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle")
                        .font(.title3)
                        .foregroundColor(Color.primaryText(isDark))
                    Text("Subscription")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))
                }
                if subscriptionManager.tier == .premium {
                    HStack(spacing: 4) {
                        Text("You're currently on Orie's")
                            .font(.footnote)
                            .foregroundColor(Color.secondaryText(isDark))
                        Text("Premium Plan")
                            .font(.footnote)
                            .foregroundColor(.yellow)
                    }
                    if subscriptionManager.aiLimit > 0 {
                        Text("AI: \(subscriptionManager.aiUsedToday)/\(subscriptionManager.aiLimit) queries today")
                            .font(.caption2)
                            .foregroundColor(Color.secondaryText(isDark))
                    }
                } else {
                    Text("You're currently on Orie's Free Plan")
                        .font(.footnote)
                        .foregroundColor(Color.secondaryText(isDark))
                    Text("AI: \(subscriptionManager.aiUsedToday)/\(subscriptionManager.aiLimit) queries today")
                        .font(.caption2)
                        .foregroundColor(Color.secondaryText(isDark))
                }
            }
            .padding(.bottom, 8)
            Divider()
            if subscriptionManager.tier == .free {
                upgradeContent
            } else {
                Button(action: {
                    Task {
                        let userId = authManager.currentUser?.id ?? ""
                        await subscriptionManager.selectFree(authManager: authManager, userId: userId)
                    }
                }) {
                    Text("Downgrade to Free")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(Color.secondaryText(isDark))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                .disabled(subscriptionManager.isLoading)
            }
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(24)
    }

    @ViewBuilder private var appCard: some View {
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
        .cornerRadius(24)
    }

    @ViewBuilder private var appToggles: some View {
        HStack {
            Text("Location")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(Color.primaryText(isDark))
            Spacer()
            Toggle("", isOn: $locationEnabled).labelsHidden()
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

    @ViewBuilder private var accountActions: some View {
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

    // MARK: - ❇️ Functions

    // MARK: 👉 Send Feedback
    private func sendFeedback() {
        guard !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let name = userName.isEmpty ? "Unknown User" : userName
        let email = authManager.currentUser?.email ?? "No email"
        let message = feedbackText

        showFeedbackModal = false
        showFeedbackSentAlert = true

        Task {
            do {
                try await authManager.withAuthRetry { accessToken in
                    try await APIService.sendFeedback(
                        accessToken: accessToken,
                        name: name,
                        email: email,
                        message: message
                    )
                }
            } catch {
                print("Failed to send feedback: \(error)")
            }
        }
    }
    // MARK: 👉 Load Profiles
    private func loadProfile() {
        Task {
            do {
                let profile = try await authManager.withAuthRetry { accessToken in
                    try await AuthService.getProfile(accessToken: accessToken)
                }
                await MainActor.run {
                    userName = profile.fullName ?? ""
                    age = profile.age ?? 0
                    weight = Int(profile.weight ?? 0)
                    height = Int(profile.height ?? 0)
                    dailyCalories = profile.dailyCalories ?? 0
                    dailyProtein = profile.dailyProtein ?? 0
                    dailyCarbs = profile.dailyCarbs ?? 0
                    dailyFats = profile.dailyFats ?? 0
                    dailySodium = profile.dailySodium ?? 0
                    dailyFibre = profile.dailyFibre ?? 0
                    dailySugar = profile.dailySugar ?? 0
                    isLoading = false
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
                isLoading = false
            } catch {
                print("Failed to load profile: \(error)")
                isLoading = false
            }
        }
    }

    // MARK: 👉 Save Profile
    private func saveProfile() {
        Task {
            do {
                try await authManager.withAuthRetry { accessToken in
                    _ = try await AuthService.updateProfile(
                        accessToken: accessToken,
                        age: age > 0 ? age : nil,
                        height: height > 0 ? Double(height) : nil,
                        weight: weight > 0 ? Double(weight) : nil,
                        dailyCalories: dailyCalories > 0 ? dailyCalories : nil,
                        dailyProtein: dailyProtein > 0 ? dailyProtein : nil,
                        dailyCarbs: dailyCarbs > 0 ? dailyCarbs : nil,
                        dailyFats: dailyFats > 0 ? dailyFats : nil,
                        dailySodium: dailySodium,
                        dailyFibre: dailyFibre,
                        dailySugar: dailySugar
                    )
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Failed to save profile: \(error)")
            }
        }
    }

}

// MARK: - ❇️ Macro Row Component
struct MacroRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let isDark: Bool
    var onSave: (() -> Void)?

    @State private var showPicker = false
    @State private var tempValue: Int

    init(label: String, value: Binding<Int>, unit: String, isDark: Bool = false, onSave: (() -> Void)? = nil) {
        self.label = label
        self._value = value
        self.unit = unit
        self.isDark = isDark
        self.onSave = onSave
        _tempValue = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        Button(action: {
            tempValue = value
            showPicker = true
        }) {
            HStack {
                Text(label)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryText(isDark))

                Spacer()

                HStack(spacing: 8) {
                    if value == 0 {
                        Text("Add \(label)")
                            .font(.footnote)
                            .foregroundColor(Color.secondaryText(isDark))
                    } else {
                        HStack(spacing: 2) {
                            Text("\(value)")
                                .font(.footnote)
                                .foregroundColor(Color.secondaryText(isDark))
                            Text(unit)
                                .font(.footnote)
                                .foregroundColor(Color.secondaryText(isDark))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            MacroPickerSheet(
                label: label,
                value: $tempValue,
                unit: unit,
                isDark: isDark,
                onDone: {
                    value = tempValue
                    showPicker = false
                    onSave?()
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.cardBackground(isDark))
        }
    }
}

// MARK: - ❇️ Macro Picker Sheet
struct MacroPickerSheet: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let isDark: Bool
    var onDone: () -> Void

    @State private var textValue: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 👉 Header
            HStack {
                Button("Cancel") {
                    onDone()
                }
                .foregroundColor(Color.secondaryText(isDark))
                .padding(.vertical, 12)
                .padding(.horizontal, 20)

                Spacer()

                Text("Set \(label)")
                    .font(.headline)
                    .foregroundColor(Color.primaryText(isDark))

                Spacer()

                Button("Done") {
                    if let newValue = Int(textValue) {
                        value = newValue
                    }
                    onDone()
                }
                .foregroundColor(Color.accentBlue)
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            // MARK: 👉 Text Field Input
            VStack(spacing: 16) {
                TextField("Enter value", text: $textValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primaryText(isDark))
                    .focused($isTextFieldFocused)
                    .padding()
            }
            .padding(.top, 32)

            Spacer()
        }
        .background(Color.cardBackground(isDark))
        .onAppear {
            textValue = "\(value)"
            isTextFieldFocused = true
        }
    }
}

// MARK: - ❇️ Profile Sheet Skeleton
struct ProfileSheetSkeleton: View {
    let isDark: Bool
    var tab: ProfileTab = .profile
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            if tab == .profile {
                // Body card skeleton
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 12)
                    }
                    .padding(.bottom, 8)

                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                }
                .padding(24)
                .background(Color.cardBackground(isDark))
                .cornerRadius(24)

                // Macros card skeleton
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 220, height: 12)
                    }
                    .padding(.bottom, 8)

                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                }
                .padding(24)
                .background(Color.cardBackground(isDark))
                .cornerRadius(24)
            }

            if tab == .settings {
                // Subscription card skeleton
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 110, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 160, height: 12)
                    }
                    .padding(.bottom, 8)

                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                }
                .padding(24)
                .background(Color.cardBackground(isDark))
                .cornerRadius(24)

                // App card skeleton
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 180, height: 12)
                    }
                    .padding(.bottom, 8)

                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                    Divider()
                    SkeletonRow(isDark: isDark)
                }
                .padding(24)
                .background(Color.cardBackground(isDark))
                .cornerRadius(24)
            }
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - ❇️ Skeleton Row
private struct SkeletonRow: View {
    let isDark: Bool

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 14)
        }
    }
}

#Preview {
    ProfileSheet()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(LocalNotificationManager.shared)
        .environmentObject(SubscriptionManager())
}
