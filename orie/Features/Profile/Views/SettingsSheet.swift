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

    @State private var showFeedbackModal = false
    @State private var feedbackText = ""
    @State private var showFeedbackSentAlert = false

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

    private func sendFeedback() {
        guard !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let name = authManager.currentUser?.email ?? "Unknown User"
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
}

#Preview {
    SettingsSheet()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(LocalNotificationManager.shared)
        .environmentObject(SubscriptionManager())
}
