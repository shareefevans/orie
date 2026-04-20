//
//  ProfileSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct ProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

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

    // MARK: - ❇️ Feedback
    @State private var showFeedbackModal = false
    @State private var feedbackText = ""
    @State private var showFeedbackSentAlert = false

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    headerView
                    ProfileTabContent(
                        isLoading: isLoading,
                        isDark: isDark,
                        age: $age,
                        weight: $weight,
                        height: $height,
                        bodyFat: $bodyFat,
                        dailyCalories: $dailyCalories,
                        dailyProtein: $dailyProtein,
                        dailyCarbs: $dailyCarbs,
                        dailyFats: $dailyFats,
                        dailySodium: $dailySodium,
                        dailyFibre: $dailyFibre,
                        dailySugar: $dailySugar,
                        onSave: saveProfile,
                        onFeedback: { feedbackText = ""; showFeedbackModal = true }
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
            loadProfile()
            Task { await subscriptionManager.loadStatus(authManager: authManager) }
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
                        Button("Cancel") { showFeedbackModal = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") { sendFeedback() }
                            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - ❇️ Header
    @ViewBuilder private var headerView: some View {
        VStack(alignment: .center, spacing: 4) {
            if isLoading {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 160, height: 24)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 14)
                    .padding(.top, 2)
            } else {
                Text(userName.isEmpty ? "User Logged Out" : userName)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText(isDark))
                Text(authManager.currentUser?.email ?? "Details Unavailable")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(.top, 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - ❇️ Send Feedback
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

    // MARK: - ❇️ Load Profile
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
                isLoading = false
            } catch {
                print("Failed to load profile: \(error)")
                isLoading = false
            }
        }
    }

    // MARK: - ❇️ Save Profile
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
                // handled by withAuthRetry
            } catch {
                print("Failed to save profile: \(error)")
            }
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
