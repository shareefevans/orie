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

    // Ingredient builder fields (UI only for now)
    @State private var ingredientFood: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientMetric: String = ""

    // Focus states for each field
    @FocusState private var focusedField: Field?

    enum Field {
        case calories, protein, carbs, fats, ingredientFood, ingredientQuantity
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Header
                    HStack {
                        Text("Update Calories")
                            .font(.system(size: 12))
                            .foregroundColor(Color.secondaryText(isDark))

                        Spacer()

                        if isKeyboardOpen {
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
                            Button("Save") {
                                saveChanges()
                            }
                            .foregroundColor(Color.accentBlue)
                            .fontWeight(.semibold)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardOpen)

                    // MARK: - Food name (read-only)
                    Text(entry.foodName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText(isDark))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Build With Ingredients section
                    Text("Build With Ingredients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 24)
                        .padding(.top, 24)

                    customDivider

                    // Food row
                    IngredientInputRow(
                        label: "Food",
                        placeholder: "Enter Item/Ingredient",
                        value: $ingredientFood,
                        isDark: isDark,
                        focusedField: $focusedField,
                        field: .ingredientFood
                    )
                    .padding(.vertical, 24)
                    .id(Field.ingredientFood)

                    customDivider

                    // Quantity row
                    IngredientInputRow(
                        label: "Quantity",
                        placeholder: "Amount",
                        value: $ingredientQuantity,
                        isDark: isDark,
                        focusedField: $focusedField,
                        field: .ingredientQuantity
                    )
                    .padding(.vertical, 24)
                    .id(Field.ingredientQuantity)

                    customDivider

                    // Metric row
                    HStack(spacing: 0) {
                        Text("Metric")
                            .font(.subheadline)
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 8) {
                            Text("Select")
                                .font(.subheadline)
                                .foregroundColor(Color.secondaryText(isDark))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 24)

                    // Add button
                    Button(action: {
                        // Add ingredient action (placeholder)
                    }) {
                        Text("Add")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                    // MARK: - Confirm Totals section
                    Text("Confirm Totals")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 24)

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

                    // Fats row
                    MacroEditRow(
                        label: "Fats",
                        value: $editedFats,
                        unit: "g",
                        color: fatsDotColor,
                        isDark: isDark,
                        focusedField: $focusedField,
                        field: .fats
                    )
                    .padding(.vertical, 24)
                    .id(Field.fats)

                    // MARK: - Bottom buttons
                    HStack(spacing: 12) {
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

                        Button(action: {
                            saveChanges()
                        }) {
                            Text("Update")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.yellow.opacity(0.8))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.never)
            .onChange(of: focusedField) { _, newField in
                if let field = newField {
                    withAnimation {
                        proxy.scrollTo(field, anchor: .center)
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardOpen)
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

// MARK: - Ingredient Input Row
struct IngredientInputRow<Field: Hashable>: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    let isDark: Bool
    var focusedField: FocusState<Field?>.Binding
    let field: Field

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.primaryText(isDark))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("", text: $value, prompt: Text(placeholder).foregroundColor(Color.placeholderText(isDark)))
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline)
                    .foregroundColor(Color.primaryText(isDark))
                    .focused(focusedField, equals: field)

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
    var entry = FoodEntry(foodName: "3 Eggs, 2 slices of tip top bread, 5 slices of wagyu salami")
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
