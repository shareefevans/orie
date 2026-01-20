//
//  CircularProgressChart.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct CircularProgressChart: View {
    let progress: Double
    var size: CGFloat = 40
    var lineWidth: CGFloat = 6
    var gradientColors: [Color] = [
        Color(red: 75/255, green: 78/255, blue: 255/255),
        Color(red: 106/255, green: 118/255, blue: 255/255)
    ]
    var isDark: Bool = false
    var animationDuration: Double = 0.8
    var animationDelay: Double = 0

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.chartBackground(isDark), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            animatedProgress = 0

            withAnimation(.easeOut(duration: animationDuration).delay(animationDelay)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: animationDuration)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    CircularProgressChart(progress: 0.65)
}
