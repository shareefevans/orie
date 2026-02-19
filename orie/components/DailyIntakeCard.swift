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
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("Daily intake")
                    .font(.system(size: 12))
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

                Text("\(remaining)cal left")
                    .font(.system(size: 12))
                    .foregroundColor(Color.accessibleYellow(isDark))
                    .padding(.top, 4)

                // Progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.chartBackground(isDark))
                        .frame(width: 87, height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 75/255, green: 78/255, blue: 255/255),
                                    Color(red: 106/255, green: 118/255, blue: 255/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 87 * CGFloat(progress), height: 6)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
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
