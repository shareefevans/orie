//
//  WeeklyOverviewCard.swift
//  orie
//
//  Created by Shareef Evans on 30/01/2026.
//

import SwiftUI

struct DailyMacroData: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
    let sugars: Int
}

struct WeeklyOverviewCard: View {
    let weekData: [DailyMacroData]
    let note: String
    let dailyCalorieGoal: Int
    let dailyProteinGoal: Int
    let dailyCarbsGoal: Int
    let dailyFatsGoal: Int
    let dailySugarGoal: Int
    var isDark: Bool = false

    @AppStorage("isWeeklyOverviewExpanded") private var isExpanded: Bool = false

    // Macro colors
    private let proteinColor = Color(red: 49/255, green: 209/255, blue: 149/255)
    private let carbsColor = Color(red: 135/255, green: 206/255, blue: 250/255)
    private let fatsColor = Color(red: 255/255, green: 180/255, blue: 50/255)
    private let sugarsColor = Color.red
    private let caloriesColor = Color(red: 106/255, green: 118/255, blue: 255/255)

    private var weekDays: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday is first day of week
        let today = calendar.startOfDay(for: Date())

        // Find the Monday of this week
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        // Days to subtract to get to Monday
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }

        // Generate all 7 days (Monday to Sunday)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private func dataForDate(_ date: Date) -> DailyMacroData? {
        let calendar = Calendar.current
        return weekData.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter day
        return formatter.string(from: date)
    }

    // Check if current time is after noon
    private var isAfterNoon: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 12
    }

    // Calculate averages for days with data (only include today after noon)
    private var daysWithData: [DailyMacroData] {
        let calendar = Calendar.current
        return weekDays.compactMap { date -> DailyMacroData? in
            guard let data = dataForDate(date), data.calories > 0 else { return nil }
            // Exclude today if it's before noon
            if calendar.isDateInToday(date) && !isAfterNoon {
                return nil
            }
            return data
        }
    }

    private var avgCalories: Int {
        guard !daysWithData.isEmpty else { return 0 }
        return daysWithData.reduce(0) { $0 + $1.calories } / daysWithData.count
    }

    private var avgProtein: Int {
        guard !daysWithData.isEmpty else { return 0 }
        return daysWithData.reduce(0) { $0 + $1.protein } / daysWithData.count
    }

    private var avgCarbs: Int {
        guard !daysWithData.isEmpty else { return 0 }
        return daysWithData.reduce(0) { $0 + $1.carbs } / daysWithData.count
    }

    private var avgFats: Int {
        guard !daysWithData.isEmpty else { return 0 }
        return daysWithData.reduce(0) { $0 + $1.fats } / daysWithData.count
    }

    private var avgSugars: Int {
        guard !daysWithData.isEmpty else { return 0 }
        return daysWithData.reduce(0) { $0 + $1.sugars } / daysWithData.count
    }

    // Check if value needs adjustment suggestion (20% threshold)
    private func caloriesSuggestion() -> (String, Bool)? {
        let threshold = Double(dailyCalorieGoal) * 0.2
        let diff = Double(avgCalories - dailyCalorieGoal)
        if diff > threshold {
            return ("Decrease", true)
        } else if diff < -threshold {
            return ("Increase", true)
        }
        return nil
    }

    private func macroSuggestion(avg: Int, goal: Int) -> (String, Bool)? {
        let threshold = Double(goal) * 0.2
        let diff = Double(avg - goal)
        if diff > threshold {
            return ("Decrease", true)
        } else if diff < -threshold {
            return ("Increase", true)
        }
        return nil
    }

    private var noteAttributedString: AttributedString {
        var noteLabel = AttributedString("*Note: ")
        noteLabel.font = .system(size: 14, weight: .semibold)
        noteLabel.foregroundColor = Color.primaryText(isDark)

        var noteText = AttributedString(note)
        noteText.font = .system(size: 14).italic()
        noteText.foregroundColor = Color.accessibleYellow(isDark)

        return noteLabel + noteText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Weekly Overview")
                .font(.system(size: 12))
                .foregroundColor(Color.secondaryText(isDark))
                .fontWeight(.medium)

            // Note section
            Text(noteAttributedString)
                .padding(.top, 8)

            // Weekly bar chart with dotted background lines
            ZStack(alignment: .bottom) {
                // Dotted horizontal lines (background)
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        Spacer()
                        DottedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .foregroundColor(Color.secondaryText(isDark).opacity(0.3))
                            .frame(height: 1)
                    }
                    Spacer()
                }
                .frame(height: 81)
                .padding(.bottom, 6) // Align with bars area

                // Chart bars
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(weekDays.enumerated()), id: \.element) { dayIndex, date in
                        let data = dataForDate(date)
                        let hasData = data != nil && data!.calories > 0
                        let baseDelay = Double(dayIndex) * 0.05

                        VStack(spacing: 8) {
                            // Bars - always show, height based on data (dots when no data)
                            HStack(alignment: .bottom, spacing: 2) {
                                MacroBar(
                                    value: hasData ? (data?.calories ?? 0) : 0,
                                    goal: dailyCalorieGoal,
                                    color: caloriesColor,
                                    showAsDot: !hasData,
                                    overThreshold: 150,
                                    animationDelay: baseDelay
                                )
                                MacroBar(
                                    value: hasData ? (data?.protein ?? 0) : 0,
                                    goal: dailyProteinGoal,
                                    color: proteinColor,
                                    showAsDot: !hasData,
                                    animationDelay: baseDelay + 0.02
                                )
                                MacroBar(
                                    value: hasData ? (data?.carbs ?? 0) : 0,
                                    goal: dailyCarbsGoal,
                                    color: carbsColor,
                                    showAsDot: !hasData,
                                    animationDelay: baseDelay + 0.04
                                )
                                MacroBar(
                                    value: hasData ? (data?.fats ?? 0) : 0,
                                    goal: dailyFatsGoal,
                                    color: fatsColor,
                                    showAsDot: !hasData,
                                    animationDelay: baseDelay + 0.06
                                )
                            }
                            .frame(height: 44, alignment: .bottom)

                            // Day label
                            VStack(spacing: 4) {
                                Text(dayLabel(date))
                                    .font(.system(size: 14, weight: isToday(date) ? .bold : .regular))
                                    .foregroundColor(Color.primaryText(isDark))
                                    .opacity(isToday(date) ? 1.0 : 0.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 16)

            // Expanded section - Daily averages
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Macro Avgs.")
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                    // Calories row
                    MacroAverageRow(
                        color: caloriesColor,
                        title: "Calories",
                        value: avgCalories,
                        goal: dailyCalorieGoal,
                        unit: "cal",
                        suggestion: caloriesSuggestion(),
                        isDark: isDark
                    )

                    // Protein row
                    MacroAverageRow(
                        color: proteinColor,
                        title: "Protein",
                        value: avgProtein,
                        goal: dailyProteinGoal,
                        unit: "g",
                        suggestion: macroSuggestion(avg: avgProtein, goal: dailyProteinGoal),
                        isDark: isDark
                    )

                    // Carbs row
                    MacroAverageRow(
                        color: carbsColor,
                        title: "Carbs",
                        value: avgCarbs,
                        goal: dailyCarbsGoal,
                        unit: "g",
                        suggestion: macroSuggestion(avg: avgCarbs, goal: dailyCarbsGoal),
                        isDark: isDark
                    )

                    // Fats row
                    MacroAverageRow(
                        color: fatsColor,
                        title: "Fats",
                        value: avgFats,
                        goal: dailyFatsGoal,
                        unit: "g",
                        suggestion: macroSuggestion(avg: avgFats, goal: dailyFatsGoal),
                        isDark: isDark
                    )

                    // Sugars row
                    MacroAverageRow(
                        color: sugarsColor,
                        title: "Sugars",
                        value: avgSugars,
                        goal: dailySugarGoal,
                        unit: "g",
                        suggestion: macroSuggestion(avg: avgSugars, goal: dailySugarGoal),
                        isDark: isDark
                    )
                }
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }
}

// MARK: - Dotted Line Shape
struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Macro Bar Component
struct MacroBar: View {
    let value: Int
    let goal: Int
    let color: Color
    var showAsDot: Bool = false
    var overThreshold: Int = 50 // Amount over goal to trigger extra height (150 for calories, 50 for macros)
    var animationDelay: Double = 0
    let chartHeight: CGFloat = 44
    let maxExtraHeight: CGFloat = 2

    @State private var animatedHeight: CGFloat = 0
    @State private var dotScale: CGFloat = 0

    private var targetHeight: CGFloat {
        if showAsDot {
            return 6 // Dot size
        }
        guard goal > 0 else { return 8 }

        let overAmount = value - goal

        if overAmount >= overThreshold {
            // Over threshold: show at 100% + up to 2px extra
            return chartHeight + maxExtraHeight
        } else if overAmount > 0 {
            // Over goal but below threshold: show at 100%
            return chartHeight
        } else {
            // Below goal: scale proportionally
            let percentage = CGFloat(value) / CGFloat(goal)
            return max(percentage * chartHeight, 8) // Min height of 8
        }
    }

    var body: some View {
        if showAsDot {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .scaleEffect(dotScale)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(animationDelay)) {
                        dotScale = 1
                    }
                }
        } else {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 6, height: animatedHeight)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(animationDelay)) {
                        animatedHeight = targetHeight
                    }
                }
        }
    }
}

// MARK: - Macro Average Row Component
struct MacroAverageRow: View {
    let color: Color
    let title: String
    let value: Int
    let goal: Int
    let unit: String
    let suggestion: (String, Bool)?
    let isDark: Bool

    private var isTooLow: Bool {
        guard let (suggestionText, show) = suggestion, show else { return false }
        return suggestionText == "Increase"
    }

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color.primaryText(isDark))

            Spacer()

            HStack(spacing: 0) {
                if isTooLow {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundColor(Color.accessibleYellow(isDark))
                        .padding(.trailing, 4)
                }

                Text(" \(value)\(unit)")
                    .foregroundColor(Color.primaryText(isDark))
                Text(" / \(goal)\(unit)")
                    .foregroundColor(.gray)

                if let (suggestionText, showSuggestion) = suggestion, showSuggestion {
                    Text(" - \(suggestionText)")
                        .foregroundColor(.gray)
                }
            }
            .font(.system(size: 12))
            .fontWeight(.regular)
            .italic()
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()

    // Find Monday of current week
    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
    components.weekday = 2
    let monday = calendar.date(from: components)!

    let sampleData = [
        DailyMacroData(date: monday, calories: 2700, protein: 150, carbs: 200, fats: 70, sugars: 25),
        DailyMacroData(date: calendar.date(byAdding: .day, value: 1, to: monday)!, calories: 2300, protein: 180, carbs: 200, fats: 65, sugars: 30),
        DailyMacroData(date: calendar.date(byAdding: .day, value: 2, to: monday)!, calories: 2300, protein: 140, carbs: 200, fats: 60, sugars: 20),
    ]

    return WeeklyOverviewCard(
        weekData: sampleData,
        note: "Weeks looking good so far, but watch your fat levels. You've been over a few times...",
        dailyCalorieGoal: 3000,
        dailyProteinGoal: 150,
        dailyCarbsGoal: 200,
        dailyFatsGoal: 65,
        dailySugarGoal: 50,
        isDark: true
    )
    .padding()
    .background(Color.black)
}
