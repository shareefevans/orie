//
//  ActivityTabView.swift
//  orie
//
//  Created by Shareef Evans on 19/01/2026.
//

import SwiftUI

struct ExerciseActivity: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let category: ExerciseCategory
}

enum ExerciseCategory: String, CaseIterable {
    case cardio = "Cardio"
    case weights = "Weights"
    case sports = "Sports"
    case misc = "Misc"
}

struct ActivityTabView: View {
    let burnedCalories: Int
    let dailyBurnGoal: Int
    var isDark: Bool = false

    @State private var selectedActivities: Set<UUID> = []

    private let exercises: [ExerciseActivity] = [
        // Cardio
        ExerciseActivity(name: "Running", iconName: "figure.run", category: .cardio),
        ExerciseActivity(name: "Walking", iconName: "figure.walk", category: .cardio),
        ExerciseActivity(name: "Cycling", iconName: "figure.outdoor.cycle", category: .cardio),
        ExerciseActivity(name: "Swimming", iconName: "figure.pool.swim", category: .cardio),
        ExerciseActivity(name: "Jump Rope", iconName: "figure.jumprope", category: .cardio),

        // Weights
        ExerciseActivity(name: "Weight Training", iconName: "figure.strengthtraining.traditional", category: .weights),
        ExerciseActivity(name: "Pilates", iconName: "figure.pilates", category: .sports),

        // Sports
        ExerciseActivity(name: "Basketball", iconName: "figure.basketball", category: .sports),
        ExerciseActivity(name: "Football", iconName: "figure.australian.football", category: .sports),
        ExerciseActivity(name: "Tennis", iconName: "figure.tennis", category: .sports),
        ExerciseActivity(name: "Soccer", iconName: "figure.indoor.soccer", category: .sports),
        ExerciseActivity(name: "NFL", iconName: "figure.american.football", category: .sports),
        ExerciseActivity(name: "Baseball", iconName: "figure.baseball", category: .sports),
        ExerciseActivity(name: "Boxing", iconName: "figure.boxing", category: .sports),
        ExerciseActivity(name: "Badminton", iconName: "figure.badminton", category: .sports),
        ExerciseActivity(name: "Cricket", iconName: "figure.cricket", category: .sports),
        ExerciseActivity(name: "Golf", iconName: "figure.golf", category: .sports),
        ExerciseActivity(name: "Hockey", iconName: "figure.hockey", category: .sports),
        ExerciseActivity(name: "MMA", iconName: "figure.martial.arts", category: .sports),
        ExerciseActivity(name: "Kickboxing", iconName: "figure.kickboxing", category: .sports),
        ExerciseActivity(name: "Rugby", iconName: "figure.rugby", category: .sports),
        ExerciseActivity(name: "Track", iconName: "figure.track.and.field", category: .sports),
        ExerciseActivity(name: "Wrestling", iconName: "figure.wrestling", category: .sports),

        // Misc
        ExerciseActivity(name: "Climbing", iconName: "figure.climbing", category: .misc),
        ExerciseActivity(name: "Yoga", iconName: "figure.yoga", category: .misc),
        ExerciseActivity(name: "Stretching", iconName: "figure.flexibility", category: .misc),
        ExerciseActivity(name: "Hiking", iconName: "figure.hiking", category: .misc),
        ExerciseActivity(name: "Dancing", iconName: "figure.dance", category: .misc),
        ExerciseActivity(name: "Skateboarding", iconName: "figure.skateboarding", category: .sports),
        ExerciseActivity(name: "Surfing", iconName: "figure.surfing", category: .sports),
        
    ]

    private func exercises(for category: ExerciseCategory) -> [ExerciseActivity] {
        exercises.filter { $0.category == category }
    }

    private var remaining: Int {
        dailyBurnGoal - burnedCalories
    }

    private var progress: Double {
        guard dailyBurnGoal > 0 else { return 0 }
        return min(Double(burnedCalories) / Double(dailyBurnGoal), 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Burned Calories Card (large, like Daily Intake)
            VStack(alignment: .leading, spacing: 0) {
                Text("Burned calories")
                    .font(.system(size: 14))
                    .foregroundColor(Color.secondaryText(isDark))
                    .fontWeight(.medium)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(burnedCalories.formatted())
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    Text("cal")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .fontWeight(.regular)
                }
                .padding(.top, 4)

                Spacer()

                // Progress bar
                LinearProgressBar(
                    progress: progress,
                    minLabel: "0",
                    maxLabel: dailyBurnGoal.formatted(),
                    gradientColors: [
                        Color(red: 255/255, green: 140/255, blue: 50/255),
                        Color(red: 255/255, green: 180/255, blue: 100/255)
                    ],
                    isDark: isDark
                )
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 180)
            .background(Color.cardBackground(isDark))
            .cornerRadius(32)
            .padding(.horizontal, 16)

            // Exercise Categories
            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                VStack(alignment: .leading, spacing: 12) {
                    // Category heading
                    Text(category.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText(isDark))
                        .fontWeight(.medium)
                        .padding(.leading, 8)
                        .padding(.top, 24)

                    // Activity buttons
                    VStack(spacing: 8) {
                        ForEach(exercises(for: category)) { exercise in
                            ExerciseActivityButton(
                                exercise: exercise,
                                isSelected: selectedActivities.contains(exercise.id),
                                isDark: isDark,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedActivities.contains(exercise.id) {
                                            selectedActivities.remove(exercise.id)
                                        } else {
                                            selectedActivities.insert(exercise.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct ExerciseActivityButton: View {
    let exercise: ExerciseActivity
    let isSelected: Bool
    var isDark: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: exercise.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(Color.iconColor(isDark))
                    .frame(width: 24)

                // Activity name
                Text(exercise.name)
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText(isDark))

                Spacer()

                // Selection circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.yellow : Color.chartBackground(isDark))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isDark ? .black : .white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground(isDark))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScrollView {
        ActivityTabView(
            burnedCalories: 350,
            dailyBurnGoal: 500
        )
    }
    .background(Color.gray.opacity(0.1))
}
