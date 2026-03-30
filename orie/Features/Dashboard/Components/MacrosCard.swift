//
//  MacrosCard.swift
//  orie
//
//  Created by Shareef Evans on 19/01/2026.
//

import SwiftUI

struct MacrosCard: View {
    let proteinConsumed: Int
    let proteinGoal: Int
    let fatsConsumed: Int
    let fatsGoal: Int
    let carbsConsumed: Int
    let carbsGoal: Int
    let sugarConsumed: Int
    let sugarGoal: Int

    var body: some View {
        VStack(spacing: 8) {
            // MARK: 👉 First row: Protein & Fats
            HStack(spacing: 8) {
                SingleMacroCard(
                    title: "Protein",
                    consumed: proteinConsumed,
                    goal: proteinGoal,
                    iconName: "triangle.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )

                SingleMacroCard(
                    title: "Fats",
                    consumed: fatsConsumed,
                    goal: fatsGoal,
                    iconName: "circle.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )
            }

            // MARK: 👉 Second row: Carbs & Sugar
            HStack(spacing: 8) {
                SingleMacroCard(
                    title: "Carbs",
                    consumed: carbsConsumed,
                    goal: carbsGoal,
                    iconName: "square.fill",
                    iconColor: Color(red: 106/255, green: 118/255, blue: 255/255),
                    gradientColors: [
                        Color(red: 75/255, green: 78/255, blue: 255/255),
                        Color(red: 106/255, green: 118/255, blue: 255/255)
                    ]
                )

                SugarCard(consumed: sugarConsumed)
            }
        }
    }
}

// MARK: - ❇️ Macro Dot Card
struct SingleMacroCard: View {
    let title: String
    let consumed: Int
    let goal: Int
    let iconName: String
    let iconColor: Color
    let gradientColors: [Color]

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
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Text("g")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .fontWeight(.regular)
            }
            .padding(.top, 4)

            Text("\(remaining)g left")
                .font(.system(size: 12))
                .foregroundColor(remaining < -25 ? .red : Color(red: 253/255, green: 181/255, blue: 0/255))
                .padding(.top, 4)
                .padding(.bottom, 24)

            Spacer()

            // MARK: 👉 Pie chart with icon and goal
            HStack(alignment: .bottom) {
                ZStack {
                    CircularProgressChart(
                        progress: progress,
                        size: 40,
                        lineWidth: 5,
                        gradientColors: gradientColors
                    )

                    // MARK: 👉 Centered icon with light background circle
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 22, height: 22)

                    Image(systemName: iconName)
                        .font(.system(size: 10))
                        .foregroundColor(iconColor)
                }

                Spacer()

                Text("\(goal)g")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(Color.white)
        .cornerRadius(32)
    }
}

// MARK: - ❇️ Alert Pill
enum AlertSeverity { case warning, danger }

struct AlertPill: View {
    let message: String
    let severity: AlertSeverity
    @State private var isPulsing = false

    private var color: Color {
        severity == .danger ? .red : Color(red: 253/255, green: 181/255, blue: 0/255)
    }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 24, height: 24)
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
            }
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.leading, 4)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear { isPulsing = true }
    }
}

func cardSuggestion(consumed: Int, goal: Int) -> (String, AlertSeverity)? {
    guard goal > 0 else { return nil }
    let ratio = Double(consumed - goal) / Double(goal)
    if ratio > 0.4 { return ("Decrease", .danger) }
    if ratio < -0.4 { return ("Increase", .danger) }
    if ratio > 0.2 { return ("Decrease", .warning) }
    if ratio < -0.2 { return ("Increase", .warning) }
    return nil
}

func heavyOverSuggestion(consumed: Int, goal: Int) -> (String, AlertSeverity)? {
    guard goal > 0 else { return nil }
    let ratio = Double(consumed - goal) / Double(goal)
    if ratio > 0.4 { return ("Decrease", .danger) }
    return nil
}

// MARK: - ❇️ Macro Dot Card
struct MacroDotCard: View {
    let title: String
    let consumed: Int
    let goal: Int
    let dotColor: Color
    var isDark: Bool = false
    var daysLogged: Int = 0

    // MARK: 👉 Original gradient blue colors
    private let gradientColors = [
        Color(red: 75/255, green: 78/255, blue: 255/255),
        Color(red: 106/255, green: 118/255, blue: 255/255)
    ]

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
                // MARK: 👉 Title with colored dot
                HStack(spacing: 8) {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)

                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondaryText(isDark))
                        .fontWeight(.medium)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(consumed.formatted())
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))

                    if goal > 0 {
                        Text("/\(goal)g")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark))
                            .fontWeight(.medium)
                    } else {
                        Text("grams")
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

// MARK: - ❇️ Macro Dot Card
struct SugarCard: View {
    let consumed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sugar")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fontWeight(.medium)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(consumed.formatted())
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.red)

                Text("grams")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .fontWeight(.regular)
            }
            .padding(.top, 4)

            Spacer()

            // MARK: 👉Heart icon in bottom left (like BurnedCard)
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(Color.white)
        .cornerRadius(32)
    }
}

// MARK: - ❇️ Nutrient Dot Card
struct NutrientDotCard: View {
    let title: String
    let consumed: Int
    let unit: String
    var displayUnit: String? = nil  // shown next to consumed number; falls back to unit
    let dotColor: Color
    var goal: Int = 0
    var isDark: Bool = false
    var daysLogged: Int = 0
    var heavyOverOnly: Bool = false

    private let gradientColors = [
        Color(red: 75/255, green: 78/255, blue: 255/255),
        Color(red: 106/255, green: 118/255, blue: 255/255)
    ]

    private func formatK(_ n: Int) -> String {
        guard n >= 1000 else { return n.formatted() }
        let value = Double(n) / 1000.0
        let truncated = Double(Int(value * 10)) / 10.0
        return truncated == Double(Int(truncated)) ? "\(Int(truncated))k" : "\(truncated)k"
    }

    private var remaining: Int {
        goal > 0 ? goal - consumed : 0
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
                        .fill(dotColor)
                        .frame(width: 6, height: 6)

                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondaryText(isDark))
                        .fontWeight(.medium)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formatK(consumed))
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))

                    if goal > 0 {
                        Text("/\(formatK(goal))\(unit)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark))
                            .fontWeight(.medium)
                    } else {
                        Text(displayUnit ?? unit)
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark))
                            .fontWeight(.regular)
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
            if heavyOverOnly && daysLogged >= 3,
               let (message, severity) = heavyOverSuggestion(consumed: consumed, goal: goal) {
                AlertPill(message: message, severity: severity)
                    .padding(12)
            }
        }
    }
}

// MARK: - ❇️ Macro Dot Card
struct BurnedMiniCard: View {
    let burned: Int
    var isDark: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // MARK: 👉Flame icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }

            // MARK: 👉Value and label
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(burned.formatted())
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                Text("burned")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondaryText(isDark))
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.cardBackground(isDark))
        .cornerRadius(20)
    }
}

// MARK: - ❇️ Macro Dot Card
struct SugarMiniCard: View {
    let consumed: Int
    var isDark: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // MARK: 👉Heart icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }

            // MARK: 👉Value and label
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(consumed.formatted())
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.red)

                Text("sugar")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondaryText(isDark))
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.cardBackground(isDark))
        .cornerRadius(20)
    }
}

#Preview {
    MacrosCard(
        proteinConsumed: 75,
        proteinGoal: 150,
        fatsConsumed: 30,
        fatsGoal: 65,
        carbsConsumed: 120,
        carbsGoal: 250,
        sugarConsumed: 0,
        sugarGoal: 50
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
