//
//  LinearProgressBar.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct LinearProgressBar: View {
    let progress: Double
    let minLabel: String
    let maxLabel: String
    var height: CGFloat = 6
    var labelSize: CGFloat = 10
    var gradientColors: [Color] = [
        Color(red: 75/255, green: 78/255, blue: 255/255),
        Color(red: 106/255, green: 118/255, blue: 255/255)
    ]

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(minLabel)
                    .font(.system(size: labelSize))
                    .foregroundColor(.gray)

                Spacer()

                Text(maxLabel)
                    .font(.system(size: labelSize))
                    .foregroundColor(.black)
            }

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    if progress > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: height)
                    }

                    if progress < 1.0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width * (1.0 - progress), height: height)
                    }
                }
            }
            .frame(height: height)
        }
    }
}

#Preview {
    LinearProgressBar(progress: 0.65, minLabel: "0", maxLabel: "2300")
        .padding()
}
