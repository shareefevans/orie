//
//  NutritionEditSheet.swift
//  orie
//
//  Created by Shareef Evans on 3/2/2026.
//

import SwiftUI

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct AddedIngredient: Identifiable {
    let id = UUID()
    let food: String
    let quantity: String
    let metric: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
}

struct NutritionEditSheet: View {
    @Environment(\.dismiss) var dismiss
    let entry: FoodEntry
    var isDark: Bool = false
    var isOffline: Bool = false
    var authManager: AuthManager? = nil
    var onSave: (Int, Double, Double, Double) -> Void

    @State private var editedCalories: String
    @State private var editedProtein: String
    @State private var editedCarbs: String
    @State private var editedFats: String

    // Ingredient builder fields
    @State private var ingredientFood: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientMetric: String = "g"

    // Ingredient list and fetch state
    @State private var addedIngredients: [AddedIngredient] = []
    @State private var isLoadingIngredient: Bool = false
    @State private var ingredientError: String? = nil

    // Expanded state
    @State private var showGetSpecific: Bool = false

    // Sheet sizing
    @State private var sheetHeight: CGFloat = 0

    // Focus states
    @FocusState private var focusedField: Field?

    enum Field {
        case calories, protein, carbs, fats, ingredientFood, ingredientQuantity
    }

    private let metrics = ["g", "oz", "ml", "cup", "tbsp", "tsp", "serving", "piece"]

    // Dot colors matching HealthTabView
    private let caloriesDotColor = Color(red: 75/255, green: 78/255, blue: 255/255)
    private let proteinDotColor = Color(red: 49/255, green: 209/255, blue: 149/255)
    private let carbsDotColor = Color(red: 135/255, green: 206/255, blue: 250/255)
    private let fatsDotColor = Color(red: 255/255, green: 180/255, blue: 50/255)

    private var customDivider: some View {
        Rectangle()
            .fill(isDark ? Color(red: 54/255, green: 54/255, blue: 54/255) : Color(red: 220/255, green: 220/255, blue: 220/255))
            .frame(height: 1)
    }

    init(
        entry: FoodEntry,
        isDark: Bool = false,
        isOffline: Bool = false,
        authManager: AuthManager? = nil,
        onSave: @escaping (Int, Double, Double, Double) -> Void,
        initialIngredients: [AddedIngredient] = [],
        initialShowGetSpecific: Bool = false
    ) {
        self.entry = entry
        self.isDark = isDark
        self.isOffline = isOffline
        self.authManager = authManager
        self.onSave = onSave
        _editedCalories = State(initialValue: "\(entry.calories ?? 0)")
        _editedProtein = State(initialValue: String(format: "%.1f", entry.protein ?? 0))
        _editedCarbs = State(initialValue: String(format: "%.1f", entry.carbs ?? 0))
        _editedFats = State(initialValue: String(format: "%.1f", entry.fats ?? 0))
        _addedIngredients = State(initialValue: initialIngredients)
        _showGetSpecific = State(initialValue: initialShowGetSpecific)
    }

    private var isKeyboardOpen: Bool {
        focusedField != nil
    }

    private var totalCalories: Int {
        addedIngredients.reduce(0) { $0 + $1.calories }
    }
    private var totalProtein: Double {
        addedIngredients.reduce(0) { $0 + $1.protein }
    }
    private var totalCarbs: Double {
        addedIngredients.reduce(0) { $0 + $1.carbs }
    }
    private var totalFats: Double {
        addedIngredients.reduce(0) { $0 + $1.fats }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Header
                    HStack {
                        Text(showGetSpecific ? "Get Specific" : "Update Calories")
                            .font(.system(size: 12))
                            .foregroundColor(Color.secondaryText(isDark))
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showGetSpecific)

                        Spacer()

                        if isKeyboardOpen {
                            Button(action: { focusedField = nil }) {
                                Image(systemName: "checkmark")
                                    .font(.callout)
                                    .foregroundColor(.black)
                                    .frame(width: 50, height: 50)
                                    .background(Color.accessibleYellow(isDark).opacity(0.55), in: Circle())
                                    .glassEffect(in: Circle())
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale))
                        } else {
                            Button("Save") {
                                commitSave()
                                dismiss()
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
                        .padding(.bottom, 24)

                    // MARK: - Confirm Totals (macro rows, hidden in Get Specific mode)
                    if !showGetSpecific {
                        VStack(spacing: 0) {
                            customDivider

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
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: - Get Specific (revealed on expand)
                    if showGetSpecific {
                        VStack(spacing: 0) {
                            customDivider

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

                            // MARK: Metric picker
                            HStack(spacing: 0) {
                                Text("Metric")
                                    .font(.subheadline)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Menu {
                                    ForEach(metrics, id: \.self) { metric in
                                        Button(metric) {
                                            ingredientMetric = metric
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(ingredientMetric)
                                            .font(.subheadline)
                                            .foregroundColor(Color.secondaryText(isDark))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.secondaryText(isDark))
                                    }
                                }
                            }
                            .padding(.vertical, 24)

                            // Error message
                            if let error = ingredientError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 8)
                            }

                            // Add button
                            Button(action: {
                                focusedField = nil
                                Task { await addIngredient() }
                            }) {
                                if isLoadingIngredient {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                } else {
                                    Text("Add")
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                        .foregroundStyle(isDark ? .white : .black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                }
                            }
                            .glassEffect(in: .capsule)
                            .disabled(isLoadingIngredient || ingredientFood.isEmpty || ingredientQuantity.isEmpty)
                            .padding(.top, 8)
                            .padding(.bottom, 16)

                            // MARK: Added ingredients list + totals
                            if !addedIngredients.isEmpty {
                                ForEach(Array(addedIngredients.enumerated()), id: \.element.id) { index, ingredient in
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(alignment: .center, spacing: 0) {
                                            Text("\(ingredient.quantity)\(ingredient.metric) \(ingredient.food)")
                                                .font(.subheadline)
                                                .foregroundColor(Color.primaryText(isDark))
                                                .lineLimit(1)
                                            Spacer()
                                            Button(action: {
                                                addedIngredients.removeAll { $0.id == ingredient.id }
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.red)
                                                    .clipShape(Circle())
                                            }
                                        }

                                        VStack(spacing: 16) {
                                            MacroDotPill(dot: caloriesDotColor, label: "Calories", value: "\(ingredient.calories)", unit: "cal", isDark: isDark)
                                            MacroDotPill(dot: proteinDotColor, label: "Protein", value: String(format: "%.0f", ingredient.protein), unit: "g", isDark: isDark)
                                            MacroDotPill(dot: carbsDotColor, label: "Carbs", value: String(format: "%.0f", ingredient.carbs), unit: "g", isDark: isDark)
                                            MacroDotPill(dot: fatsDotColor, label: "Fats", value: String(format: "%.0f", ingredient.fats), unit: "g", isDark: isDark)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .padding(.vertical, 16)

                                    if index < addedIngredients.count - 1 {
                                        customDivider
                                            .padding(.vertical, 8)
                                    }
                                }

                                customDivider
                                    .padding(.vertical, 24)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Total Breakdown")
                                        .font(.system(size: 12))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.accessibleYellow(isDark))
                                        .padding(.bottom, 16)
                                        .padding(.top, 16)

                                    VStack(spacing: 16) {
                                        MacroDotPill(dot: caloriesDotColor, label: "Calories", value: "\(totalCalories)", unit: "cal", isDark: isDark, bold: true)
                                        MacroDotPill(dot: proteinDotColor, label: "Protein", value: String(format: "%.1f", totalProtein), unit: "g", isDark: isDark, bold: true)
                                        MacroDotPill(dot: carbsDotColor, label: "Carbs", value: String(format: "%.1f", totalCarbs), unit: "g", isDark: isDark, bold: true)
                                        MacroDotPill(dot: fatsDotColor, label: "Fats", value: String(format: "%.1f", totalFats), unit: "g", isDark: isDark, bold: true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 4)

                                customDivider
                                    .padding(.vertical, 24)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // MARK: - Bottom buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            if showGetSpecific {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    showGetSpecific = false
                                }
                            } else {
                                dismiss()
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .foregroundStyle(isDark ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .glassEffect(in: .capsule)

                        if !isOffline {
                            if showGetSpecific {
                                Button(action: {
                                    onSave(totalCalories, totalProtein, totalCarbs, totalFats)
                                    dismiss()
                                }) {
                                    Text("Update")
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.accessibleYellow(isDark).opacity(0.55), in: .capsule)
                                }
                                .glassEffect(in: .capsule)
                                .disabled(addedIngredients.isEmpty)
                                .opacity(addedIngredients.isEmpty ? 0.5 : 1.0)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            } else {
                                Button(action: {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                        showGetSpecific = true
                                    }
                                }) {
                                    Text("Get Specific")
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.accessibleYellow(isDark).opacity(0.55), in: .capsule)
                                }
                                .glassEffect(in: .capsule)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showGetSpecific)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                    }
                )
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
        .onPreferenceChange(ContentHeightKey.self) { height in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                sheetHeight = height
            }
        }
        .presentationDetents(sheetHeight > 0 ? [.height(sheetHeight)] : [.fraction(0.85)])
    }

    private func addIngredient() async {
        guard !ingredientFood.isEmpty, !ingredientQuantity.isEmpty else { return }
        guard let authManager = authManager else {
            ingredientError = "Sign in required."
            return
        }
        isLoadingIngredient = true
        ingredientError = nil
        let query = "\(ingredientQuantity) \(ingredientMetric) \(ingredientFood)"
        do {
            let result = try await authManager.withAuthRetry { accessToken in
                try await APIService.getNutrition(for: query, accessToken: accessToken)
            }
            addedIngredients.append(AddedIngredient(
                food: ingredientFood,
                quantity: ingredientQuantity,
                metric: ingredientMetric,
                calories: result.calories,
                protein: result.protein,
                carbs: result.carbs,
                fats: result.fats
            ))
            ingredientFood = ""
            ingredientQuantity = ""
        } catch APIError.upgradeRequired {
            ingredientError = "AI lookup requires Premium."
        } catch APIError.aiLimitReached {
            ingredientError = "Daily AI limit reached. Resets at midnight."
        } catch {
            ingredientError = "Could not find nutrition info. Try again."
        }
        isLoadingIngredient = false
    }

    private func commitSave() {
        let calories = Int(editedCalories) ?? entry.calories ?? 0
        let protein = Double(editedProtein) ?? entry.protein ?? 0
        let carbs = Double(editedCarbs) ?? entry.carbs ?? 0
        let fats = Double(editedFats) ?? entry.fats ?? 0
        onSave(calories, protein, carbs, fats)
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
                    .foregroundColor(Color.secondaryText(isDark))
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
                    .foregroundColor(Color.secondaryText(isDark))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField.wrappedValue = field
        }
    }
}

// MARK: - Macro Dot Row
private struct MacroDotPill: View {
    let dot: Color
    let label: String
    let value: String
    let unit: String
    var isDark: Bool = false
    var bold: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(dot)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color.primaryText(isDark))
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 13))
                    .fontWeight(bold ? .semibold : .regular)
                    .foregroundColor(Color.primaryText(isDark))
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondaryText(isDark))
            }
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

    let sampleIngredients: [AddedIngredient] = [
        AddedIngredient(food: "Egg", quantity: "3", metric: "piece", calories: 210, protein: 18.0, carbs: 1.5, fats: 14.0),
        AddedIngredient(food: "Tip Top Bread", quantity: "2", metric: "piece", calories: 140, protein: 4.0, carbs: 26.0, fats: 2.0),
        AddedIngredient(food: "Wagyu Salami", quantity: "5", metric: "piece", calories: 120, protein: 6.0, carbs: 0.5, fats: 10.5)
    ]

    return NutritionEditSheet(
        entry: entry,
        isDark: true,
        onSave: { _, _, _, _ in },
        initialIngredients: sampleIngredients,
        initialShowGetSpecific: true
    )
}
