//
//  MealSuggestionCard.swift
//  orie
//

import SwiftUI

struct MealSuggestionCard: View {
    let suggestion: MealSuggestion
    let isDark: Bool
    let isAdded: Bool
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader
            macroRow
            addButton
        }
        .padding(24)
        .background(
            isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var cardHeader: some View {
        Text("\(suggestion.servingSize) of \(suggestion.foodName)")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color.primaryText(isDark))
            .lineLimit(2)
    }

    private var macroRow: some View {
        HStack {
            MealMacroColumn(
                label: "calories",
                value: Double(suggestion.calories),
                color: Color(red: 106/255, green: 118/255, blue: 255/255),
                isDark: isDark,
                isInteger: true
            )
            Spacer()
            MealMacroColumn(
                label: "protein",
                value: suggestion.protein,
                color: Color(red: 49/255, green: 209/255, blue: 149/255),
                isDark: isDark
            )
            Spacer()
            MealMacroColumn(
                label: "carbs",
                value: suggestion.carbs,
                color: Color(red: 135/255, green: 206/255, blue: 250/255),
                isDark: isDark
            )
            Spacer()
            MealMacroColumn(
                label: "fat",
                value: suggestion.fats,
                color: Color(red: 255/255, green: 204/255, blue: 51/255),
                isDark: isDark
            )
        }
    }

    private var addButton: some View {
        HStack(spacing: 10) {
            Button(action: onAdd) {
                HStack(spacing: 6) {
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text(isAdded ? "Successfully Logged" : "Log")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    isAdded
                        ? Color(red: 49/255, green: 209/255, blue: 149/255).opacity(0.55)
                        : Color(red: 0.25, green: 0.45, blue: 1.0).opacity(0.55),
                    in: RoundedRectangle(cornerRadius: 32, style: .continuous)
                )
                #if os(iOS)
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: 32, style: .continuous)
                )
                #endif
            }
            .buttonStyle(.plain)
            .disabled(isAdded)

            if !isAdded {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            Color.red.opacity(0.55),
                            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
                        )
                        #if os(iOS)
                        .glassEffect(
                            .regular.interactive(),
                            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
                        )
                        #endif
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isAdded)
    }
}

struct MealMacroColumn: View {
    let label: String
    let value: Double
    let color: Color
    let isDark: Bool
    var isInteger: Bool = false

    private var valueText: String {
        isInteger ? "\(Int(value))" : String(format: "%.1fg", value)
    }

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(valueText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.secondaryText(isDark))
        }
    }
}

#Preview("Default") {
    MealSuggestionCard(
        suggestion: MealSuggestion(
            foodName: "Grilled Chicken Breast",
            calories: 165,
            protein: 31.0,
            carbs: 0.0,
            fats: 3.6,
            servingSize: "100g"
        ),
        isDark: true,
        isAdded: false,
        onAdd: {},
        onCancel: {}
    )
    .padding()
    .background(Color.black)
}

#Preview("Added state") {
    MealSuggestionCard(
        suggestion: MealSuggestion(
            foodName: "Grilled Chicken Breast",
            calories: 165,
            protein: 31.0,
            carbs: 0.0,
            fats: 3.6,
            servingSize: "100g"
        ),
        isDark: true,
        isAdded: true,
        onAdd: {},
        onCancel: {}
    )
    .padding()
    .background(Color.black)
}
