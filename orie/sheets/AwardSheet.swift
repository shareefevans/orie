//
//  AwardSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct AwardSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager

    private var isDark: Bool { themeManager.isDarkMode }

    @State private var achievements: [Achievement] = []
    @State private var totalUnlocked = 0
    @State private var totalAchievements = 0
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    private var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }.sorted { $0.percentage > $1.percentage }
    }

    private var nextAchievement: Achievement? {
        lockedAchievements.first
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: Header
                    VStack(spacing: 4) {
                        Text("Awards")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primaryText(isDark))

                        Text("\(totalAchievements) Badges")
                            .font(.subheadline)
                            .foregroundColor(Color.secondaryText(isDark))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                    // MARK: Content
                    if isLoading {
                        AwardSheetSkeleton(isDark: isDark)
                            .padding(.horizontal)
                    } else if let error = errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Color.secondaryText(isDark))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            // MARK: Next Achievement Card
                            if let next = nextAchievement {
                                NextAchievementCard(achievement: next, isDark: isDark)
                            }

                            // MARK: Unlocked Section
                            if !unlockedAchievements.isEmpty {
                                Text("Unlocked")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .padding(.top, 8)

                                VStack(spacing: 12) {
                                    ForEach(unlockedAchievements) { achievement in
                                        AwardCard(
                                            achievement: achievement,
                                            isUnlocked: true,
                                            isDark: isDark
                                        )
                                    }
                                }
                            }

                            // MARK: Locked Section
                            if !lockedAchievements.isEmpty {
                                Text("Locked")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .padding(.top, 8)

                                VStack(spacing: 12) {
                                    ForEach(lockedAchievements) { achievement in
                                        AwardCard(
                                            achievement: achievement,
                                            isUnlocked: false,
                                            isDark: isDark
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.appBackground(isDark))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
        .task {
            await loadAchievements()
        }
    }

    private func loadAchievements() async {
        guard let accessToken = authManager.getAccessToken() else {
            errorMessage = "Please log in to view achievements"
            isLoading = false
            return
        }

        do {
            let result = try await AchievementService.getAchievements(accessToken: accessToken)
            self.achievements = result.achievements
            self.totalUnlocked = result.totalUnlocked
            self.totalAchievements = result.totalAchievements
            self.isLoading = false
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Key '\(key.stringValue)' not found: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type): \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found for \(type): \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   Unknown decoding error")
            }
            self.errorMessage = "Failed to parse achievements"
            self.isLoading = false
        } catch {
            print("❌ Failed to load achievements: \(error)")
            self.errorMessage = "Failed to load achievements"
            self.isLoading = false
        }
    }
}

// MARK: - Next Achievement Card
struct NextAchievementCard: View {
    let achievement: Achievement
    let isDark: Bool

    private var truncatedName: String {
        let maxLength = 8
        if achievement.name.count > maxLength {
            return String(achievement.name.prefix(maxLength)) + "..."
        }
        return achievement.name
    }

    private var progress: Double {
        guard achievement.target > 0 else { return 0 }
        return Double(achievement.currentProgress) / Double(achievement.target)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Badge Image
            AsyncImage(url: URL(string: achievement.image)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                case .failure:
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .frame(width: 44, height: 44)
                @unknown default:
                    EmptyView()
                }
            }

            // Title
            Text("Next - \(truncatedName)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.primaryText(isDark))

            Spacer()

            // Progress Bar
            LinearProgressBar(
                progress: progress,
                minLabel: "\(achievement.currentProgress)",
                maxLabel: "\(achievement.target)",
                height: 6,
                labelSize: 11,
                isDark: isDark
            )
            .frame(width: 100)
        }
        .padding(16)
        .background(Color.cardBackground(isDark))
        .cornerRadius(24)
    }
}

// MARK: - Award Card Component
struct AwardCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let isDark: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Badge Image
            AsyncImage(url: URL(string: achievement.image)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                case .failure:
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .frame(width: 44, height: 44)
                @unknown default:
                    EmptyView()
                }
            }
            .opacity(isUnlocked ? 1.0 : 0.4)

            // Title and Description
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText(isDark))

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(Color.secondaryText(isDark))
            }
            .opacity(isUnlocked ? 1.0 : 0.4)

            Spacer()

            // Checkmark for unlocked
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color.cardBackground(isDark))
        .cornerRadius(24)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Award Sheet Skeleton
struct AwardSheetSkeleton: View {
    let isDark: Bool
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Next achievement skeleton
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 16)

                Spacer()

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 6)
            }
            .padding(16)
            .background(Color.cardBackground(isDark))
            .cornerRadius(24)

            // Section header skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 14)
                .padding(.top, 8)

            // Award card skeletons
            ForEach(0..<4, id: \.self) { _ in
                AwardCardSkeleton(isDark: isDark)
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

// MARK: - Award Card Skeleton
struct AwardCardSkeleton: View {
    let isDark: Bool

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 12)
            }

            Spacer()

            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
        }
        .padding(16)
        .background(Color.cardBackground(isDark))
        .cornerRadius(24)
    }
}

#Preview {
    AwardSheet()
        .environmentObject(ThemeManager())
        .environmentObject(AuthManager())
}
