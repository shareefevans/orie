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
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Text("cal")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .fontWeight(.regular)
            }
            .padding(.top, 4)

            Text("\(remaining) remaining")
                .font(.system(size: 12))
                .foregroundColor(remaining > 0 ? .yellow : .red)
                .padding(.top, 4)

            Spacer()

            // Progress bar
            LinearProgressBar(
                progress: progress,
                minLabel: "0",
                maxLabel: goal.formatted()
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(32)
    }
}

#Preview {
    DailyIntakeCard(consumed: 1500, goal: 2300)
        .padding()
        .background(Color.gray.opacity(0.1))
}
