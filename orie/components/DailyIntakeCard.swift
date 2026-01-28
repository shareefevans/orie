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

    private var remaining: Int {
        goal - consumed
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daily intake")
                .font(.system(size: 14))
                .foregroundColor(Color.secondaryText(isDark))
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText(isDark))

                Text("cal")
                    .font(.system(size: 14))
                    .foregroundColor(Color.primaryText(isDark))
                    .fontWeight(.regular)
            }
            .padding(.top, 4)

            Text("\(remaining) remaining")
                .font(.system(size: 14))
                .foregroundColor(remaining < -100 ? .red : .yellow)
                .padding(.top, 4)

            // MARK: 👉 Meal Progress bar with labels above
            VStack(spacing: 8) {
                HStack {
                    Text("0")
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondaryText(isDark))
                    Spacer()
                    Text(goal.formatted())
                        .font(.system(size: 12))
                        .foregroundColor(Color.primaryText(isDark))
                }

                MealProgressBar(
                    progress: progress,
                    meals: meals,
                    height: 6,
                    isDark: isDark
                )
            }
            .padding(.top, 32)
        }
        .padding(.top, 32)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
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
