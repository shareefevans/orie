//
//  ProfileSetupView.swift
//  orie
//

import SwiftUI

// MARK: - Supporting Types

enum SetupGoal: String, CaseIterable, Identifiable {
    case cutFat = "Cut Fat"
    case gainMuscle = "Gain Muscle"
    case maintain = "Maintain"
    case recomp = "Cut Fat + Gain Muscle"
    var id: String { rawValue }
}

enum ExerciseLevel: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"
    case extraActive = "Extra Active"
    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary:         return 1.2
        case .lightlyActive:     return 1.375
        case .moderatelyActive:  return 1.55
        case .veryActive:        return 1.725
        case .extraActive:       return 1.9
        }
    }
}

struct GeneratedMacros {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    var sodium: Int
    var fibre: Int
    var sugar: Int
}

// MARK: - TDEE Calculator

private enum TDEECalculator {
    static func calculate(
        gender: String,
        age: Int,
        heightCM: Double,
        weightKG: Double,
        exerciseLevel: ExerciseLevel,
        goal: SetupGoal
    ) -> GeneratedMacros {
        let bmr: Double = gender.lowercased() == "female"
            ? (10 * weightKG) + (6.25 * heightCM) - (5 * Double(age)) - 161
            : (10 * weightKG) + (6.25 * heightCM) - (5 * Double(age)) + 5

        let tdee = bmr * exerciseLevel.multiplier

        let targetCals: Double
        let proteinPerKg: Double
        let fatPerKg: Double

        switch goal {
        case .cutFat:     targetCals = tdee - 500; proteinPerKg = 2.2; fatPerKg = 0.8
        case .gainMuscle: targetCals = tdee + 300; proteinPerKg = 1.8; fatPerKg = 1.0
        case .maintain:   targetCals = tdee;       proteinPerKg = 1.6; fatPerKg = 1.0
        case .recomp:     targetCals = tdee - 500; proteinPerKg = 2.4; fatPerKg = 0.9
        }

        let protein = Int(proteinPerKg * weightKG)
        let fats    = Int(fatPerKg * weightKG)
        let carbs   = max(0, Int(targetCals) - (protein * 4) - (fats * 9)) / 4
        let sugar   = (goal == .cutFat || goal == .recomp) ? 30 : 40

        return GeneratedMacros(
            calories: max(1200, Int(targetCals)),
            protein: protein, carbs: carbs, fats: fats,
            sodium: 2300, fibre: 30, sugar: sugar
        )
    }
}

// MARK: - Profile Setup View

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    private var isDark: Bool { themeManager.isDarkMode }

    @State private var useOrieHelp = false

    // Shared
    @State private var isMetric = true
    @State private var gender = "Select"

    // Manual
    @State private var manualHeight = 0
    @State private var manualWeight = 0
    @State private var manualCalories = 0
    @State private var manualProtein = 0
    @State private var manualCarbs = 0
    @State private var manualFats = 0
    @State private var manualSodium = 0
    @State private var manualSugar = 0
    @State private var manualFibre = 0

    // Orie-assisted
    @State private var age = 0
    @State private var height = 0
    @State private var weight = 0
    @State private var exerciseLevel: ExerciseLevel? = nil
    @State private var goal: SetupGoal? = nil

    // Presentation
    @State private var isCalculating = false
    @State private var generatedMacros: GeneratedMacros? = nil
    @State private var isSaving = false
    @State private var calculatingTask: Task<Void, Never>? = nil
    @State private var showValidationErrors = false
    @State private var showValidationAlert = false

    @State private var activePicker: SetupWheelPicker? = nil
    @State private var activeInput: InputField? = nil

    enum SetupWheelPicker: Identifiable {
        case system, gender, exerciseLevel, goal
        var id: Int {
            switch self {
            case .system:        return 0
            case .gender:        return 1
            case .exerciseLevel: return 2
            case .goal:          return 3
            }
        }
    }

    enum InputField: String, Identifiable {
        case age, height, weight
        case manualHeight, manualWeight
        case calories, protein, carbs, fats, sodium, sugar, fibre
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            // MARK: - ❇️ Background (back-most)
            Color.appBackground(isDark)
                .ignoresSafeArea()

            // MARK: - ❇️ Squiggle (fixed, behind card and button)
            VStack(spacing: 0) {
                Image("squiggle_dark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, -150)
                Spacer()
            }

            // MARK: - ❇️ Scroll content (card scrolls over squiggle)
            ScrollView {
                VStack(spacing: 8) {
                    // Transparent spacer so card starts below squiggle
                    Color.clear.frame(height: 125)

                    if let macros = generatedMacros {
                        // MARK: - ❇️ Results heading (16px above card)
                        VStack(spacing: 6) {
                            Text("Review Your Breakdown")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.primaryText(isDark))
                                .multilineTextAlignment(.center)
                            Text("Please take a moment to review your breakdown. If you'd like to make any changes you can do so now, or alternatively from your profile page within settings.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondaryText(isDark))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                        // MARK: - ❇️ Results card (replaces selection card)
                        ResultsCard(
                            initialMacros: macros,
                            isDark: isDark,
                            isSaving: $isSaving,
                            onBack: {
                                generatedMacros = nil
                                useOrieHelp = false
                            },
                            onComplete: { finalMacros in Task { await saveOrie(macros: finalMacros) } }
                        )
                    } else {
                        // MARK: - ❇️ Toggle (above card)
                        NativeSegmentedControl(
                            options: ["Manual", "Assisted"],
                            selectedIndex: Binding(
                                get: { useOrieHelp ? 1 : 0 },
                                set: { useOrieHelp = $0 == 1; showValidationErrors = false }
                            ),
                            isDark: isDark
                        )
                        .frame(height: 50)
                        .padding(.horizontal, 16)

                        // MARK: - ❇️ Selection card
                        VStack(spacing: 16) {
                            VStack(spacing: 0) {
                                if useOrieHelp {
                                    orieRows
                                } else {
                                    manualRows
                                }
                            }

                            HStack(spacing: 12) {
                                Button(action: handleDone) {
                                    Group {
                                        if isSaving {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        } else {
                                            Text(useOrieHelp ? "Calculate" : "Done")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.black)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.accessibleYellow(isDark).opacity(0.55), in: Capsule())
                                }
                                .glassEffect(in: Capsule())
                                .disabled(isSaving)
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(Color.cardBackground(isDark))
                        .cornerRadius(32)
                        .padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 40)
                }
            }
            .blur(radius: isCalculating ? 3 : 0)

            // MARK: - ❇️ Header buttons (front-most)
            VStack {
                HStack(spacing: 8) {
                    Button(action: { Task { await authManager.logout() } }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(in: Circle())

                    HStack(spacing: 6) {
                        Image(systemName: "circle.hexagonpath.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text(generatedMacros != nil ? "Calorie Results" : "Create Account")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.primaryText(isDark))
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .glassEffect(.regular.interactive(), in: Capsule())

                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, 8)
                Spacer()
            }

            // MARK: - ❇️ Calculating overlay
            if isCalculating {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.hexagonpath.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.primaryText(isDark))
                        Text("Orie's Working...")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.primaryText(isDark))
                    }

                    Text("Please wait a moment whilst\nwe configure your calories")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText(isDark))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Button(action: cancelCalculation) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isDark ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .glassEffect(in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(Color.cardBackground(isDark))
                .cornerRadius(32)
                .padding(.horizontal, 48)
            }
        }
        .sheet(item: $activePicker) { picker in
            wheelPickerSheet(for: picker)
        }
        .sheet(item: $activeInput) { field in
            inputSheet(for: field)
        }
        .alert("Required Information Missing", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter the required information before continuing.")
        }
    }

    // MARK: - Manual Rows

    @ViewBuilder private var manualRows: some View {
        SetupPickerRow(label: "System", value: isMetric ? "Metric" : "Imperial", isDark: isDark) { activePicker = .system }
        setupDivider
        SetupPickerRow(label: "Gender", value: gender, isDark: isDark, isInvalid: showValidationErrors && gender == "Select") { activePicker = .gender }
        setupDivider
        SetupValueRow(label: "Height", value: manualHeight > 0 ? "\(manualHeight) \(isMetric ? "CM" : "FT")" : "Enter \(isMetric ? "CM" : "FT")", isDark: isDark, isInvalid: showValidationErrors && manualHeight == 0) { activeInput = .manualHeight }
        setupDivider
        SetupValueRow(label: "Weight", value: manualWeight > 0 ? "\(manualWeight) \(isMetric ? "KG" : "LBS")" : "Enter \(isMetric ? "KG" : "LBS")", isDark: isDark, isInvalid: showValidationErrors && manualWeight == 0) { activeInput = .manualWeight }
        setupDivider
        SetupValueRow(label: "Calories",      value: manualCalories > 0 ? "\(manualCalories)"     : "Enter", isDark: isDark, isInvalid: showValidationErrors && manualCalories == 0) { activeInput = .calories }
        setupDivider
        SetupValueRow(label: "Protein",       value: manualProtein  > 0 ? "\(manualProtein) g"    : "Enter", isDark: isDark, isInvalid: showValidationErrors && manualProtein == 0)  { activeInput = .protein }
        setupDivider
        SetupValueRow(label: "Carbohydrates", value: manualCarbs    > 0 ? "\(manualCarbs) g"      : "Enter", isDark: isDark, isInvalid: showValidationErrors && manualCarbs == 0)    { activeInput = .carbs }
        setupDivider
        SetupValueRow(label: "Fats",          value: manualFats     > 0 ? "\(manualFats) g"       : "Enter", isDark: isDark, isInvalid: showValidationErrors && manualFats == 0)     { activeInput = .fats }
        setupDivider
        SetupValueRow(label: "Sodium",        value: manualSodium   > 0 ? "\(manualSodium) mg"    : "Enter", isDark: isDark) { activeInput = .sodium }
        setupDivider
        SetupValueRow(label: "Sugars",        value: manualSugar    > 0 ? "\(manualSugar) g"      : "Enter", isDark: isDark) { activeInput = .sugar }
        setupDivider
        SetupValueRow(label: "Fibre",         value: manualFibre    > 0 ? "\(manualFibre) g"      : "Enter", isDark: isDark) { activeInput = .fibre }
    }

    // MARK: - Orie Rows

    @ViewBuilder private var orieRows: some View {
        SetupPickerRow(label: "System",         value: isMetric ? "Metric" : "Imperial", isDark: isDark) { activePicker = .system }
        setupDivider
        SetupPickerRow(label: "Gender",         value: gender, isDark: isDark, isInvalid: showValidationErrors && gender == "Select") { activePicker = .gender }
        setupDivider
        SetupValueRow(label: "Age",    value: age    > 0 ? "\(age)"                                                   : "Enter",                             isDark: isDark, isInvalid: showValidationErrors && age == 0)    { activeInput = .age }
        setupDivider
        SetupValueRow(label: "Height", value: height > 0 ? "\(height) \(isMetric ? "CM" : "FT")"  : "Enter \(isMetric ? "CM" : "FT")",  isDark: isDark, isInvalid: showValidationErrors && height == 0) { activeInput = .height }
        setupDivider
        SetupValueRow(label: "Weight", value: weight > 0 ? "\(weight) \(isMetric ? "KG" : "LBS")" : "Enter \(isMetric ? "KG" : "LBS")", isDark: isDark, isInvalid: showValidationErrors && weight == 0) { activeInput = .weight }
        setupDivider
        SetupPickerRow(label: "Exercise Level", value: exerciseLevel?.rawValue ?? "Select", isDark: isDark, isInvalid: showValidationErrors && exerciseLevel == nil) { activePicker = .exerciseLevel }
        setupDivider
        SetupPickerRow(label: "Goal",           value: goal?.rawValue ?? "Select",          isDark: isDark, isInvalid: showValidationErrors && goal == nil)          { activePicker = .goal }
    }

    private var setupDivider: some View {
        Rectangle()
            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
            .frame(height: 1)
    }

    // MARK: - Input Sheet

    @ViewBuilder
    private func inputSheet(for field: InputField) -> some View {
        Group {
            switch field {
            case .age:          MacroPickerSheet(label: "Age",           value: $age,            unit: "yrs",                   isDark: isDark, onDone: { activeInput = nil })
            case .height:       MacroPickerSheet(label: "Height",        value: $height,         unit: isMetric ? "cm" : "ft",  isDark: isDark, onDone: { activeInput = nil })
            case .weight:       MacroPickerSheet(label: "Weight",        value: $weight,         unit: isMetric ? "kg" : "lbs", isDark: isDark, onDone: { activeInput = nil })
            case .manualHeight: MacroPickerSheet(label: "Height",        value: $manualHeight,   unit: isMetric ? "cm" : "ft",  isDark: isDark, onDone: { activeInput = nil })
            case .manualWeight: MacroPickerSheet(label: "Weight",        value: $manualWeight,   unit: isMetric ? "kg" : "lbs", isDark: isDark, onDone: { activeInput = nil })
            case .calories:     MacroPickerSheet(label: "Calories",      value: $manualCalories, unit: "cal",                   isDark: isDark, onDone: { activeInput = nil })
            case .protein:      MacroPickerSheet(label: "Protein",       value: $manualProtein,  unit: "g",                     isDark: isDark, onDone: { activeInput = nil })
            case .carbs:        MacroPickerSheet(label: "Carbohydrates", value: $manualCarbs,    unit: "g",                     isDark: isDark, onDone: { activeInput = nil })
            case .fats:         MacroPickerSheet(label: "Fats",          value: $manualFats,     unit: "g",                     isDark: isDark, onDone: { activeInput = nil })
            case .sodium:       MacroPickerSheet(label: "Sodium",        value: $manualSodium,   unit: "mg",                    isDark: isDark, onDone: { activeInput = nil })
            case .sugar:        MacroPickerSheet(label: "Sugars",        value: $manualSugar,    unit: "g",                     isDark: isDark, onDone: { activeInput = nil })
            case .fibre:        MacroPickerSheet(label: "Fibre",         value: $manualFibre,    unit: "g",                     isDark: isDark, onDone: { activeInput = nil })
            }
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.cardBackground(isDark))
    }

    // MARK: - Wheel Picker Sheet

    private var systemBinding: Binding<String> {
        Binding(
            get: { isMetric ? "Metric" : "Imperial" },
            set: { isMetric = $0 == "Metric" }
        )
    }

    private var exerciseLevelBinding: Binding<String> {
        Binding(
            get: { exerciseLevel?.rawValue ?? "Select" },
            set: { val in exerciseLevel = val == "Select" ? nil : ExerciseLevel.allCases.first { $0.rawValue == val } }
        )
    }

    private var goalBinding: Binding<String> {
        Binding(
            get: { goal?.rawValue ?? "Select" },
            set: { val in goal = val == "Select" ? nil : SetupGoal.allCases.first { $0.rawValue == val } }
        )
    }

    @ViewBuilder
    private func wheelPickerSheet(for picker: SetupWheelPicker) -> some View {
        switch picker {
        case .system:
            WheelPickerSheet(options: ["Metric", "Imperial"], selection: systemBinding) { activePicker = nil }
        case .gender:
            WheelPickerSheet(options: ["Select", "Male", "Female", "Other"], selection: $gender) { activePicker = nil }
        case .exerciseLevel:
            WheelPickerSheet(options: ["Select"] + ExerciseLevel.allCases.map(\.rawValue), selection: exerciseLevelBinding) { activePicker = nil }
        case .goal:
            WheelPickerSheet(options: ["Select"] + SetupGoal.allCases.map(\.rawValue), selection: goalBinding) { activePicker = nil }
        }
    }

    // MARK: - Actions

    private var orieFieldsComplete: Bool {
        gender != "Select" && age > 0 && height > 0 && weight > 0 &&
        exerciseLevel != nil && goal != nil
    }

    private var manualFieldsComplete: Bool {
        gender != "Select" && manualHeight > 0 && manualWeight > 0 &&
        manualCalories > 0 && manualProtein > 0 &&
        manualCarbs > 0 && manualFats > 0
    }

    private func handleDone() {
        if useOrieHelp {
            guard orieFieldsComplete else {
                showValidationErrors = true
                showValidationAlert = true
                return
            }
            showValidationErrors = false
            isCalculating = true
            generatedMacros = nil
            calculatingTask = Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                guard !Task.isCancelled else { return }
                let hCM = isMetric ? Double(height) : Double(height) * 30.48
                let wKG = isMetric ? Double(weight) : Double(weight) * 0.453592
                generatedMacros = TDEECalculator.calculate(
                    gender: gender, age: age, heightCM: hCM, weightKG: wKG,
                    exerciseLevel: exerciseLevel ?? .moderatelyActive,
                    goal: goal ?? .maintain
                )
                isCalculating = false
            }
        } else {
            guard manualFieldsComplete else {
                showValidationErrors = true
                showValidationAlert = true
                return
            }
            showValidationErrors = false
            Task { await saveManual() }
        }
    }

    private func cancelCalculation() {
        calculatingTask?.cancel()
        calculatingTask = nil
        isCalculating = false
    }

    private func saveManual() async {
        isSaving = true
        defer { isSaving = false }
        let hCM = isMetric ? Double(manualHeight) : Double(manualHeight) * 30.48
        let wKG = isMetric ? Double(manualWeight) : Double(manualWeight) * 0.453592
        do {
            try await authManager.withAuthRetry { token in
                _ = try await AuthService.updateProfile(
                    accessToken: token,
                    gender: gender.isEmpty ? nil : gender,
                    height: manualHeight > 0 ? hCM : nil,
                    weight: manualWeight > 0 ? wKG : nil,
                    dailyCalories: manualCalories > 0 ? manualCalories : nil,
                    dailyProtein:  manualProtein  > 0 ? manualProtein  : nil,
                    dailyCarbs:    manualCarbs    > 0 ? manualCarbs    : nil,
                    dailyFats:     manualFats     > 0 ? manualFats     : nil,
                    dailySodium:   manualSodium   > 0 ? manualSodium   : nil,
                    dailyFibre:    manualFibre    > 0 ? manualFibre    : nil,
                    dailySugar:    manualSugar    > 0 ? manualSugar    : nil
                )
            }
        } catch { print("Profile setup save failed: \(error)") }
        authManager.markProfileSetupCompleted()
    }

    private func saveOrie(macros: GeneratedMacros) async {
        isSaving = true
        defer { isSaving = false }
        let hCM = isMetric ? Double(height) : Double(height) * 30.48
        let wKG = isMetric ? Double(weight) : Double(weight) * 0.453592
        do {
            try await authManager.withAuthRetry { token in
                _ = try await AuthService.updateProfile(
                    accessToken: token,
                    gender: gender.isEmpty ? nil : gender,
                    age: age > 0 ? age : nil,
                    height: height > 0 ? hCM : nil,
                    weight: weight > 0 ? wKG : nil,
                    dailyCalories: macros.calories,
                    dailyProtein:  macros.protein,
                    dailyCarbs:    macros.carbs,
                    dailyFats:     macros.fats,
                    dailySodium:   macros.sodium,
                    dailyFibre:    macros.fibre,
                    dailySugar:    macros.sugar
                )
            }
        } catch { print("Profile setup save failed: \(error)") }
        authManager.markProfileSetupCompleted()
    }
}

// MARK: - Results Card

struct ResultsCard: View {
    let isDark: Bool
    @Binding var isSaving: Bool
    var onBack: () -> Void
    var onComplete: (GeneratedMacros) -> Void

    @State private var macros: GeneratedMacros
    @State private var activeInput: ResultField? = nil

    enum ResultField: String, Identifiable {
        case calories, protein, carbs, fats, sodium, sugar, fibre
        var id: String { rawValue }
    }

    init(initialMacros: GeneratedMacros, isDark: Bool, isSaving: Binding<Bool>, onBack: @escaping () -> Void, onComplete: @escaping (GeneratedMacros) -> Void) {
        self.isDark = isDark
        self._isSaving = isSaving
        self.onBack = onBack
        self.onComplete = onComplete
        self._macros = State(initialValue: initialMacros)
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                SetupValueRow(label: "Calories",      value: "\(macros.calories) cal", isDark: isDark) { activeInput = .calories }
                divider
                SetupValueRow(label: "Protein",       value: "\(macros.protein) g",   isDark: isDark) { activeInput = .protein }
                divider
                SetupValueRow(label: "Carbohydrates", value: "\(macros.carbs) g",     isDark: isDark) { activeInput = .carbs }
                divider
                SetupValueRow(label: "Fats",          value: "\(macros.fats) g",      isDark: isDark) { activeInput = .fats }
                divider
                SetupValueRow(label: "Sodium",        value: "\(macros.sodium) mg",   isDark: isDark) { activeInput = .sodium }
                divider
                SetupValueRow(label: "Sugar",         value: "\(macros.sugar) g",     isDark: isDark) { activeInput = .sugar }
                divider
                SetupValueRow(label: "Fibre",         value: "\(macros.fibre) g",     isDark: isDark) { activeInput = .fibre }
            }

            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Re-Configure")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isDark ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .glassEffect(in: Capsule())

                Button(action: { onComplete(macros) }) {
                    Group {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Complete")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accessibleYellow(isDark).opacity(0.55), in: Capsule())
                }
                .glassEffect(in: Capsule())
                .disabled(isSaving)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
        .padding(.horizontal, 16)
        .sheet(item: $activeInput) { field in
            Group {
                switch field {
                case .calories: MacroPickerSheet(label: "Calories",      value: $macros.calories, unit: "cal", isDark: isDark, onDone: { activeInput = nil })
                case .protein:  MacroPickerSheet(label: "Protein",       value: $macros.protein,  unit: "g",   isDark: isDark, onDone: { activeInput = nil })
                case .carbs:    MacroPickerSheet(label: "Carbohydrates", value: $macros.carbs,    unit: "g",   isDark: isDark, onDone: { activeInput = nil })
                case .fats:     MacroPickerSheet(label: "Fats",          value: $macros.fats,     unit: "g",   isDark: isDark, onDone: { activeInput = nil })
                case .sodium:   MacroPickerSheet(label: "Sodium",        value: $macros.sodium,   unit: "mg",  isDark: isDark, onDone: { activeInput = nil })
                case .sugar:    MacroPickerSheet(label: "Sugar",         value: $macros.sugar,    unit: "g",   isDark: isDark, onDone: { activeInput = nil })
                case .fibre:    MacroPickerSheet(label: "Fibre",         value: $macros.fibre,    unit: "g",   isDark: isDark, onDone: { activeInput = nil })
                }
            }
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.cardBackground(isDark))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
            .frame(height: 1)
    }
}

// MARK: - Row Components

struct SetupPickerRow: View {
    let label: String
    let value: String
    let isDark: Bool
    var isInvalid: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isInvalid {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.accessibleYellow(isDark))
                }
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText(isDark))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondaryText(isDark))
                }
            }
            .padding(.vertical, 24)
        }
        .buttonStyle(.plain)
    }
}

struct SetupValueRow: View {
    let label: String
    let value: String
    let isDark: Bool
    var isInvalid: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isInvalid {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.accessibleYellow(isDark))
                }
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText(isDark))
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(Color.accessibleYellow(isDark))
                }
            }
            .padding(.vertical, 24)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Segmented Control

struct NativeSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int
    var isDark: Bool

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { i in
                if selectedIndex == i {
                    Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedIndex = i } }) {
                        Text(options[i])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.accessibleYellow(isDark).opacity(0.55), in: Capsule())
                    }
                    .glassEffect(in: Capsule())
                } else {
                    Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedIndex = i } }) {
                        Text(options[i])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.secondaryText(isDark))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(3)
        .background(Color.cardBackground(isDark), in: RoundedRectangle(cornerRadius: 100, style: .continuous))
    }
}

// MARK: - Wheel Picker Sheet

struct WheelPickerSheet: View {
    let options: [String]
    @Binding var selection: String
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") { onDone() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.accentBlue)
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .tag(option)
                        .padding(.vertical, 16)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 220)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(290)])
        .presentationBackground(Color.cardBackground(true))
    }
}

// MARK: - Previews

#Preview("Initial – Manual") {
    ProfileSetupView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}

#Preview("Initial – Assisted") {
    // Wraps the view and flips to the assisted tab on appear
    struct AssistedWrapper: View {
        @State private var dummy = false
        var body: some View {
            ProfileSetupView()
                .environmentObject(AuthManager())
                .environmentObject(ThemeManager())
                .onAppear {
                    // SwiftUI will render with default state; tap "Assisted" in the canvas to switch
                }
        }
    }
    return AssistedWrapper()
}

#Preview("Loading Modal") {
    // Shows the calculating overlay over the assisted form
    struct LoadingWrapper: View {
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                // Simulated blurred background
                VStack { Spacer() }
                    .blur(radius: 3)

                Color.black.opacity(0.5).ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.hexagonpath.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Text("Orie's Working...")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Please wait a moment whilst\nwe configure your calories")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                        .lineSpacing(4)
                    
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .glassEffect(in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(Color(red: 28/255, green: 28/255, blue: 28/255))
                .cornerRadius(32)
                .padding(.horizontal, 48)
            }
        }
    }
    return LoadingWrapper()
}

#Preview("Results Card") {
    let mockMacros = GeneratedMacros(
        calories: 2200,
        protein: 200,
        carbs: 180,
        fats: 90,
        sodium: 3000,
        fibre: 50,
        sugar: 60
    )
    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 8) {
                Color.clear.frame(height: 60)

                VStack(spacing: 6) {
                    Text("Review Your Breakdown")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Please take a moment to review your breakdown. If you'd like to make any changes you can do so now, or alternatively from your profile page within settings.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                ResultsCard(
                    initialMacros: mockMacros,
                    isDark: true,
                    isSaving: .constant(false),
                    onBack: {},
                    onComplete: { _ in }
                )
            }
        }
    }
}
