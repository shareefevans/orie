//
//  MacroCircularCard.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct MacroCircularCard: View {
    let title: String
    let consumed: Int
    let goal: Int
    let unit: String

    private var remaining: Int {
        goal - consumed
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .fontWeight(.regular)
            }
            .padding(.top, 4)

            Text("\(remaining)g remaining")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.top, 4)

            Spacer()

            // Circular pie chart with goal label
            HStack(alignment: .bottom) {
                CircularProgressChart(progress: progress)
                Spacer()
                Text("\(goal)g")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }
            .padding(.top, 48)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(24)
    }
}

#Preview {
    HStack(spacing: 8) {
        MacroCircularCard(title: "Carbohydrates", consumed: 120, goal: 250, unit: "grams")
        MacroCircularCard(title: "Fats", consumed: 30, goal: 65, unit: "grams")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
