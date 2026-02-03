//
//  NutritionEditSheet.swift
//  orie
//
//  Created by Shareef Evans on 3/2/2026.
//

import SwiftUI

struct NutritionEditSheet: View {
    @Environment(\.dismiss) var dismiss
    let entry: FoodEntry
    var isDark: Bool = false
    var onSave: (Int, Double, Double, Double) -> Void

    @State private var editedCalories: String
    @State private var editedProtein: String
    @State private var editedCarbs: String
    @State private var editedFats: String

    // Focus states for each field
    @FocusState private var focusedField: Field?

    enum Field {
        case calories, protein, carbs, fats
    }

    // Dot colors matching HealthTabView
    private let caloriesDotColor = Color(red: 75/255, green: 78/255, blue: 255/255)
    private let proteinDotColor = Color(red: 49/255, green: 209/255, blue: 149/255)
    private let carbsDotColor = Color(red: 135/255, green: 206/255, blue: 250/255)
    private let fatsDotColor = Color(red: 255/255, green: 180/255, blue: 50/255)

    // Custom divider color #363636
    private var customDivider: some View {
        Rectangle()
            .fill(Color(red: 54/255, green: 54/255, blue: 54/255))
            .frame(height: 1)
    }

    init(entry: FoodEntry, isDark: Bool = false, onSave: @escaping (Int, Double, Double, Double) -> Void) {
        self.entry = entry
        self.isDark = isDark
        self.onSave = onSave
        _editedCalories = State(initialValue: "\(entry.calories ?? 0)")
        _editedProtein = State(initialValue: String(format: "%.1f", entry.protein ?? 0))
        _editedCarbs = State(initialValue: String(format: "%.1f", entry.carbs ?? 0))
        _editedFats = State(initialValue: String(format: "%.1f", entry.fats ?? 0))
    }

    private var isKeyboardOpen: Bool {
        focusedField != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header (pinned at top)
            HStack {
                Text("Edit Calories")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondaryText(isDark))

                Spacer()

                if isKeyboardOpen {
                    // Checkmark button when keyboard is open (matches TopNavigationBar style)
                    Button(action: {
                        focusedField = nil
                    }) {
                        Image(systemName: "checkmark")
                            .font(.callout)
                            .foregroundColor(isDark ? .black : .white)
                            .frame(width: 50, height: 50)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(Circle().fill(Color.yellow))
                            }
                            .clipShape(Circle())
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale))
                } else {
                    // Done button when keyboard is closed
                    Button("Done") {
                        saveChanges()
                    }
                    .foregroundColor(Color.accentBlue)
                    .fontWeight(.semibold)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardOpen)

            VStack(spacing: 24) {
                // MARK: - Food name (read-only)
                Text(entry.foodName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText(isDark))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 24)
            }

            // MARK: - Editable fields with dividers
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        customDivider

                        // Calories row
                        MacroEditRow(
                            label: "Calories",
                            value: $editedCalories,
                            unit: "cal",
                            color: caloriesDotColor,
                            isDark: isDark,
                            focusedField: $focusedField,
                            field: .calories
                        )
                        .padding(.vertical, 24)
                        .id(Field.calories)

                        customDivider

                        // Protein row
                        MacroEditRow(
                            label: "Protein",
                            value: $editedProtein,
                            unit: "g",
                            color: proteinDotColor,
                            isDark: isDark,
                            focusedField: $focusedField,
                            field: .protein
                        )
                        .padding(.vertical, 24)
                        .id(Field.protein)

                        customDivider

                        // Carbs row
                        MacroEditRow(
                            label: "Carbs",
                            value: $editedCarbs,
                            unit: "g",
                            color: carbsDotColor,
                            isDark: isDark,
                            focusedField: $focusedField,
                            field: .carbs
                        )
                        .padding(.vertical, 24)
                        .id(Field.carbs)

                        customDivider

                        // Fat row
                        MacroEditRow(
                            label: "Fat",
                            value: $editedFats,
                            unit: "g",
                            color: fatsDotColor,
                            isDark: isDark,
                            focusedField: $focusedField,
                            field: .fats
                        )
                        .padding(.vertical, 24)
                        .id(Field.fats)

                        // Extra space for keyboard
                        Color.clear
                            .frame(height: 8)
                    }
                }
                .scrollDismissesKeyboard(.never)
                .onChange(of: focusedField) { _, newField in
                    if let field = newField {
                        withAnimation {
                            proxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 8)

            // MARK: - Cancel button at bottom (hidden when keyboard is open)
            if !isKeyboardOpen {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 8)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardOpen)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 32)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.cardBackground(isDark))
    }

    private func saveChanges() {
        let calories = Int(editedCalories) ?? entry.calories ?? 0
        let protein = Double(editedProtein) ?? entry.protein ?? 0
        let carbs = Double(editedCarbs) ?? entry.carbs ?? 0
        let fats = Double(editedFats) ?? entry.fats ?? 0

        onSave(calories, protein, carbs, fats)
        dismiss()
    }
}

// MARK: - Editable Macro Row
struct MacroEditRow<Field: Hashable>: View {
    let label: String
    @Binding var value: String
    let unit: String
    let color: Color
    let isDark: Bool
    var focusedField: FocusState<Field?>.Binding
    let field: Field

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(Color.primaryText(isDark))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline)
                    .foregroundColor(Color.primaryText(isDark))
                    .frame(width: 60)
                    .focused(focusedField, equals: field)

                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(Color.secondaryText(isDark))
                    .frame(width: 24, alignment: .leading)

                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField.wrappedValue = field
        }
    }
}

#Preview {
    var entry = FoodEntry(foodName: "KFC Zinger Burger")
    entry.calories = 450
    entry.protein = 25.0
    entry.carbs = 35.0
    entry.fats = 22.0
    entry.isLoading = false

    return NutritionEditSheet(
        entry: entry,
        isDark: true,
        onSave: { _, _, _, _ in }
    )
}
