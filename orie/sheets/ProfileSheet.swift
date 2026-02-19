//
//  ProfileSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI
import UIKit

struct ProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localNotificationManager: LocalNotificationManager

    // MARK: - ❇️ User data
    @State private var userName = ""
    @State private var dailyCalories = 0
    @State private var dailyProtein = 0
    @State private var dailyCarbs = 0
    @State private var dailyFats = 0
    @State private var isLoading = true

    // MARK: - ❇️ Personal data
    @State private var age = 0
    @State private var weight = 0
    @State private var height = 0
    @State private var bodyFat = 0
    @State private var gender = ""

    // MARK: - ❇️ Settings
    @State private var locationEnabled = true
    @State private var showNotificationDeniedAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showFeedbackModal = false
    @State private var feedbackText = ""
    @State private var isSendingFeedback = false
    @State private var showFeedbackSentAlert = false

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    
                    // MARK: - ❇️ Header
                    // MARK: 👉 Header - Settings and Name centered
                    VStack(alignment: .center, spacing: 2) {
                        Text("Settings")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primaryText(isDark))

                        Text(userName.isEmpty ? "User logged Out" : userName)
                            .font(.footnote)
                            .foregroundColor(Color.secondaryText(isDark))
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    // MARK: 👉 Feedback button
                    Button(action: {
                        feedbackText = ""
                        showFeedbackModal = true
                    }) {
                        Text("Feedback")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .glassEffect(.regular.interactive())

                    if isLoading {
                        ProfileSheetSkeleton(isDark: isDark)
                    } else {
                        // MARK: - ❇️ Body Section
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Body")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primaryText(isDark))

                                    Text("Set up your body composition below.")
                                        .font(.footnote)
                                        .foregroundColor(Color.secondaryText(isDark))
                                }
                            }
                            .padding(.bottom, 8)

                            Divider()

                            // MARK: 👉 Macro rows
                            MacroRow(label: "Age", value: $age, unit : "yrs", isDark: isDark, onSave: saveProfile)
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

                        // MARK: - ❇️ Macronutrients Section
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Macros")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primaryText(isDark))

                                    Text("Set your daily calorie and macro goals.")
                                        .font(.footnote)
                                        .foregroundColor(Color.secondaryText(isDark))
                                }
                            }
                            .padding(.bottom, 8)

                            Divider()

                            // MARK: 👉 Macro rows
                            MacroRow(label: "Calories", value: $dailyCalories, unit: "c", isDark: isDark, onSave: saveProfile)
                            Divider()
                            MacroRow(label: "Protein", value: $dailyProtein, unit: "g", isDark: isDark, onSave: saveProfile)
                            Divider()
                            MacroRow(label: "Carbohydrates", value: $dailyCarbs, unit: "g", isDark: isDark, onSave: saveProfile)
                            Divider()
                            MacroRow(label: "Fats", value: $dailyFats, unit: "g", isDark: isDark, onSave: saveProfile)
                        }
                        .padding(24)
                        .background(Color.cardBackground(isDark))
                        .cornerRadius(24)

                        // MARK: - ❇️ App Section
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("App")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primaryText(isDark))

                                    Text("Manage your app settings.")
                                        .font(.footnote)
                                        .foregroundColor(Color.secondaryText(isDark))
                                        .lineLimit(2)
                                }
                            }
                            .padding(.bottom, 8)

                            Divider()

                            // MARK: 👉 Settings toggles
                            HStack {
                                Text("Location")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.primaryText(isDark))
                                Spacer()
                                Toggle("", isOn: $locationEnabled)
                                    .labelsHidden()
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
                                Toggle("", isOn: Binding(
                                    get: { localNotificationManager.notificationsEnabled },
                                    set: { newValue in
                                        if newValue {
                                            Task {
                                                let granted = await localNotificationManager.requestAuthorization()
                                                if granted {
                                                    localNotificationManager.notificationsEnabled = true
                                                } else {
                                                    showNotificationDeniedAlert = true
                                                }
                                            }
                                        } else {
                                            localNotificationManager.notificationsEnabled = false
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }

                            Divider()

                            HStack {
                                Text("Dark Mode")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.primaryText(isDark))
                                Spacer()
                                Toggle("", isOn: $themeManager.isDarkMode)
                                    .labelsHidden()
                            }

                            Divider()

                            // MARK: 👉 Log Out
                            Button(action: {
                                Task {
                                    await authManager.logout()
                                    dismiss()
                                }
                            }) {
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

                            // MARK: 👉 Delete Account
                            Button(action: {
                                showDeleteAccountAlert = true
                            }) {
                                HStack {
                                    Text("Delete Account")
                                        .font(.footnote)
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(24)
                        .background(Color.cardBackground(isDark))
                        .cornerRadius(24)
                    }
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
            loadProfile()
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
                        dailyFats: dailyFats > 0 ? dailyFats : nil
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
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
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
}
