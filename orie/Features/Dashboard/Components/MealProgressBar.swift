//
//  MealProgressBar.swift
//  orie
//
//  Created by Shareef Evans on 20/01/2026.
//

import SwiftUI

struct MealBubble: Identifiable {
    let id = UUID()
    let timestamp: Date
    let protein: Double
    let carbs: Double
    let fats: Double

    var totalMacros: Double {
        protein + carbs + fats
    }
}

struct MealProgressBar: View {
    let progress: Double
    let meals: [MealBubble]
    var height: CGFloat = 6
    var isDark: Bool = false
    var animationDuration: Double = 0.8
    var animationDelay: Double = 0

    private let fillColor = Color(red: 106/255, green: 118/255, blue: 255/255)

    private var unfilledColor: Color {
        Color.chartBackground(isDark)
    }

    @State private var animatedProgress: Double = 0

    // MARK: - ❇️ Body
    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let filledWidth = barWidth * CGFloat(animatedProgress)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(unfilledColor)
                    .frame(width: barWidth, height: height)

                if animatedProgress > 0 {
                    Capsule()
                        .fill(fillColor)
                        .frame(width: filledWidth, height: height)
                }
            }
        }
        .frame(height: height)
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

struct PillData {
    enum PillType {
        case time
        case protein
        case carbs
        case fats
    }

    let type: PillType
    let widthFraction: CGFloat
}

struct ColoredPillView: View {
    let pill: PillData
    let width: CGFloat
    let height: CGFloat
    let proteinColor: Color
    let carbsColor: Color
    let fatsColor: Color
    let timeColor: Color
    let overallProgress: Double
    let pillStartProgress: Double
    let pillEndProgress: Double

    private var fillColor: Color {
        switch pill.type {
        case .time:
            return timeColor
        case .protein:
            return proteinColor
        case .carbs:
            return carbsColor
        case .fats:
            return fatsColor
        }
    }

    // MARK: 👉 Calculate how much of this pill should be filled (0 to 1)
    private var fillFraction: CGFloat {
        if overallProgress >= pillEndProgress {
            return 1.0
        } else if overallProgress <= pillStartProgress {
            return 0.0
        } else {
            let pillRange = pillEndProgress - pillStartProgress
            let progressInPill = overallProgress - pillStartProgress
            return CGFloat(progressInPill / pillRange)
        }
    }

    var body: some View {
        // MARK: 👉Only show the colored pill if there's any fill
        if fillFraction > 0 {
            Capsule()
                .fill(fillColor)
                .frame(width: width * fillFraction, height: height)
                .frame(width: width, alignment: .leading)
        } else {
            // Empty spacer to maintain layout
            Color.clear
                .frame(width: width, height: height)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("100% progress - 4 meals")
            .font(.caption)
        MealProgressBar(
            progress: 1.0,
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
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!,
                    protein: 10,
                    carbs: 50,
                    fats: 5
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!,
                    protein: 30,
                    carbs: 40,
                    fats: 12
                )
            ],
            height: 6
        )
        .padding(.horizontal, 16)

        Text("75% progress - 4 meals")
            .font(.caption)
        MealProgressBar(
            progress: 0.75,
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
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!,
                    protein: 10,
                    carbs: 50,
                    fats: 5
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!,
                    protein: 30,
                    carbs: 40,
                    fats: 12
                )
            ],
            height: 6
        )
        .padding(.horizontal, 16)

        Text("50% progress - 2 meals")
            .font(.caption)
        MealProgressBar(
            progress: 0.5,
            meals: [
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
                    protein: 25,
                    carbs: 40,
                    fats: 12
                ),
                MealBubble(
                    timestamp: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date())!,
                    protein: 30,
                    carbs: 35,
                    fats: 15
                )
            ],
            height: 6
        )
        .padding(.horizontal, 16)

        Text("No meals - 30%")
            .font(.caption)
        MealProgressBar(
            progress: 0.3,
            meals: [],
            height: 6
        )
        .padding(.horizontal, 16)
    }
    .padding()
    .background(Color.white)
}
