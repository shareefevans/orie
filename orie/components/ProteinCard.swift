//
//  ProteinCard.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct ProteinCard: View {
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
            Text("Protein")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Text("grams")
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

            // Progress bar
            LinearProgressBar(
                progress: progress,
                minLabel: "0",
                maxLabel: "\(goal)g"
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .background(Color.white)
        .cornerRadius(24)
    }
}

#Preview {
    ProteinCard(consumed: 75, goal: 150)
        .padding()
        .background(Color.gray.opacity(0.1))
}
