//
//  BurnedCard.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct BurnedCard: View {
    let burned: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Burned")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(burned.formatted())
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

            // MARK: 👉 Fire icon in bottom left
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(32)
    }
}

#Preview {
    BurnedCard(burned: 0)
        .padding()
        .background(Color.gray.opacity(0.1))
}
