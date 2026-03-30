//
//  DailyIntakeCard.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct DailyIntakeCard: View {
    let consumed: Int
    let goal: Int
    let meals: [MealBubble]
    var isDark: Bool = false
    var daysLogged: Int = 0

    private func formatK(_ n: Int) -> String {
        guard n >= 1000 else { return n.formatted() }
        let value = Double(n) / 1000.0
        let truncated = Double(Int(value * 10)) / 10.0
        return truncated == Double(Int(truncated)) ? "\(Int(truncated))k" : "\(truncated)k"
    }

    private var formattedConsumed: String { formatK(consumed) }
    private var formattedGoal: String { formatK(goal) }

    private var remaining: Int {
        goal - consumed
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 106/255, green: 118/255, blue: 255/255))
                        .frame(width: 6, height: 6)
                    Text("Calorie Avg.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondaryText(isDark))
                        .fontWeight(.medium)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedConsumed)
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))

                    if goal > 0 {
                        Text("/\(formattedGoal)cal")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark))
                            .fontWeight(.medium)
                    } else {
                        Text("cal")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark))
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
        .overlay(alignment: .topTrailing) {
            if daysLogged >= 3, let (message, severity) = cardSuggestion(consumed: consumed, goal: goal) {
                AlertPill(message: message, severity: severity)
                    .padding(12)
            }
        }
    }
}

#Preview {
    DailyIntakeCard(
        consumed: 1500,
        goal: 2300,
        meals: [
            MealBubble(
                timestamp: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
                protein: 20,
                carbs: 35,
                fats: 15
            ),
            MealBubble(
                timestamp: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!,
                protein: 35,
                carbs: 25,
                fats: 18
            )
        ]
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
