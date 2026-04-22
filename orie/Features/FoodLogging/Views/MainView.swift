//
//  MainView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct MainView: View {

    // MARK: - ❇️ Environment & Theme

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - ❇️ ViewModel

    @StateObject private var vm = FoodLoggingViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()

    // MARK: - ❇️ UI State

    @State private var currentInput = ""
    @State private var showAwards = false
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var selectedTab: String = "consumed"
    @State private var isDateSelectionMode = false
    @FocusState private var isInputFocused: Bool
    @State private var editingEntryId: UUID? = nil
    @State private var consumedTabId: UUID = UUID()
    @State private var healthTabId: UUID = UUID()
    @AppStorage("isIntakeCardExpanded") private var isIntakeCardExpanded: Bool = false
    @AppStorage("isOrieAssistEnabled") private var isOrieAssistEnabled: Bool = true
    @AppStorage("hasShownFirstMealCelebration") private var hasShownFirstMealCelebration: Bool = false
    @State private var isShowingFoodInput: Bool = false
    @State private var autocompleteSuggestion: String? = nil
    @State private var keyboardHeight: CGFloat = 0
    @State private var shouldScrollToInput = false
    @State private var triggerMicFromNav = false
    @State private var triggerStopMicFromNav = false
    @State private var isRecordingFromField = false
    @State private var triggerCameraFromNav = false
    @State private var showOrieChat = false
    @State private var showPremiumRequired = false
    @State private var showFirstMealCelebration = false
    @State private var awaitingFirstEntryCalculation = false
    @State private var showIntakeCardNudge = false
    @State private var pulseIntakeCard = false

    // MARK: - ❇️ Computed Properties

    private var isDark: Bool { themeManager.isDarkMode }

    private var filteredEntries: [FoodEntry] {
        vm.foodEntries.filter { Calendar.current.isDate($0.entryDate, inSameDayAs: selectedDate) }
    }

    private enum MealPeriod: String, CaseIterable, Hashable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case night = "Night"

        var icon: String {
            switch self {
            case .morning: return "sun.horizon.circle"
            case .afternoon: return "sun.max.circle"
            case .night: return "moon.stars.circle"
            }
        }

        static func from(timestamp: Date) -> MealPeriod {
            let hour = Calendar.current.component(.hour, from: timestamp)
            switch hour {
            case 0..<12: return .morning
            case 12..<18: return .afternoon
            default: return .night
            }
        }
    }

    private var entriesByPeriod: [(period: MealPeriod, entries: [FoodEntry])] {
        let sorted = filteredEntries.sorted()
        return MealPeriod.allCases.compactMap { period in
            let entries = sorted.filter { MealPeriod.from(timestamp: $0.timestamp) == period }
            return entries.isEmpty ? nil : (period: period, entries: entries)
        }
    }

    private var consumedCalories: Int {
        filteredEntries.reduce(0) { $0 + ($1.calories ?? 0) }
    }

    private var remainingCalories: Int {
        vm.dailyCalorieGoal - consumedCalories
    }

    private var calorieProgress: Double {
        guard vm.dailyCalorieGoal > 0 else { return 0 }
        return min(Double(consumedCalories) / Double(vm.dailyCalorieGoal), 1.0)
    }

    private var consumedProtein: Int {
        Int(filteredEntries.reduce(0.0) { $0 + ($1.protein ?? 0) })
    }

    private var consumedCarbs: Int {
        Int(filteredEntries.reduce(0.0) { $0 + ($1.carbs ?? 0) })
    }

    private var consumedFats: Int {
        Int(filteredEntries.reduce(0.0) { $0 + ($1.fats ?? 0) })
    }

    private var consumedFibre: Int {
        Int(filteredEntries.reduce(0.0) { $0 + ($1.fibre ?? 0) })
    }

    private var consumedSodium: Int {
        Int(filteredEntries.reduce(0.0) { $0 + ($1.sodium ?? 0) })
    }

    private var consumedSugar: Int {
        Int(filteredEntries.reduce(0.0) { $0 + ($1.sugar ?? 0) })
    }

    private func macroSuggestion(consumed: Int, goal: Int) -> (String, Bool)? {
        let threshold = Double(goal) * 0.2
        let diff = Double(consumed - goal)
        if diff > threshold { return ("Decrease", true) }
        else if diff < -threshold { return ("Increase", true) }
        return nil
    }

    private func nutritionSuggestion(consumed: Int, goal: Int) -> (String, Bool)? {
        let threshold = Double(goal) * 0.2
        let diff = Double(consumed - goal)
        if diff > threshold { return ("Decrease", true) }
        return nil
    }

    private var mealBubbles: [MealBubble] {
        filteredEntries
            .filter { !$0.isLoading }
            .map { MealBubble(timestamp: $0.timestamp, protein: $0.protein ?? 0, carbs: $0.carbs ?? 0, fats: $0.fats ?? 0) }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - ❇️ UI Actions

    private func dismissAllInputs() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isDateSelectionMode = false
        }
        editingEntryId = nil
        isInputFocused = false
    }

    // MARK: - ❇️ Autocomplete Pill Overlay

    @ViewBuilder
    private var autocompletePillOverlay: some View {
        if let suggestion = autocompleteSuggestion, isInputFocused, keyboardHeight > 0 {
            VStack {
                Spacer()
                Button {
                    let s = suggestion
                    withAnimation(.easeInOut(duration: 0.2)) { autocompleteSuggestion = nil }
                    currentInput = ""
                    vm.addFoodEntry(foodName: s, date: selectedDate, isOffline: !networkMonitor.isConnected)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isInputFocused = true }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(suggestion)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 44)
                    .glassEffect(in: Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, keyboardHeight + 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .allowsHitTesting(true)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .zIndex(12)
        }
    }

    // MARK: - ❇️ Tab Selector Content

    @ViewBuilder
    private var tabSelectorContent: some View {
        if isDateSelectionMode {
            ScrollViewReader { dateProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(vm.datesInCurrentMonth(), id: \.self) { date in
                            DateButton(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                isDark: isDark,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedDate = date
                                    }
                                }
                            )
                            .id(date)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .mask(
                    HStack(spacing: 0) {
                        LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 32)
                        Color.black
                        LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 32)
                    }
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { dateProxy.scrollTo(selectedDate, anchor: .center) }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
            .padding(.bottom, 24)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - ❇️ Consumed Tab Content

    @ViewBuilder
    private func mealPeriodHeader(period: MealPeriod, calories: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: period.icon)
                .font(.system(size: 14))
                .foregroundColor(Color.accessibleYellow(isDark))
                .frame(width: 24, height: 24)
                .background(isDark ? Color(red: 0x2A/255, green: 0x2A/255, blue: 0x2A/255) : Color(red: 0xF7/255, green: 0xF7/255, blue: 0xF7/255), in: Circle())
            Text("\(period.rawValue) - \(calories) calories")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.secondaryText(isDark))
        }
        .padding(.leading, 4)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(Color.cardBackground(isDark), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, -24)
    }

    @ViewBuilder
    private var firstEntryCard: some View {
        VStack(spacing: 20) {
            Text("Log Your First Entry")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.primaryText(isDark))
                .multilineTextAlignment(.center)

            (
                Text("Track your intake here. You can ")
                + Text(Image(systemName: "plus")).baselineOffset(-1)
                + Text(" type, ")
                + Text(Image(systemName: "mic.fill")).baselineOffset(-1)
                + Text(" talk, and ")
                + Text(Image(systemName: "camera.fill")).baselineOffset(-1)
                + Text(" photograph your meal. Once done, enter or tap the ")
                + Text(Image(systemName: "arrow.turn.down.left")).baselineOffset(-1)
                + Text(" 'tab' in the bottom right of your keyboard to log, ")
                + Text("Orie will handle the breakdown.")
                    .foregroundColor(Color.accessibleYellow(isDark))
            )
            .font(.system(size: 14))
            .foregroundColor(Color.secondaryText(isDark))
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            Button(action: {
                isShowingFoodInput = true
                isInputFocused = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Tap to Enter Food...")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Color.primaryText(isDark))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
            }
            .glassEffect(.regular.tint(Color.yellow.opacity(0.18)).interactive(), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 100)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var lazyManCard: some View {
        VStack(spacing: 4) {
            Image(isDark ? "lazy_man" : "lazy_man_light")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .frame(maxWidth: .infinity)
                .opacity(0.25)
                .padding(.bottom, -12)

            Text("WAKE UP!!!")
                .font(.system(size: 14, weight: .black))
                .italic()
                .foregroundColor(Color(red: 47/255, green: 47/255, blue: 47/255))

            Text("New Day New You.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 47/255, green: 47/255, blue: 47/255))
        }
        .padding(.top, 70)
    }

    @ViewBuilder
    private func consumedTabContent(proxy: ScrollViewProxy) -> some View {
        if selectedTab == "consumed" {
            VStack(spacing: 8) {
                if vm.isEntriesLoading {
                    ConsumedTabSkeleton(isDark: isDark)
                } else {
                    // Daily intake card
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Today's intake")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText(isDark))
                            .fontWeight(.medium)

                        Text("\(remainingCalories) calories remaining")
                            .font(.system(size: 16))
                            .foregroundColor(remainingCalories < -100 ? .red : Color.primaryText(isDark))
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                            .fontWeight(.medium)

                        VStack(spacing: 8) {
                            HStack {
                                Text("\(consumedCalories) cal")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.accessibleYellow(isDark))
                                Spacer()
                                Text("\(vm.dailyCalorieGoal) cal")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.secondaryText(isDark))
                            }

                            MealProgressBar(progress: calorieProgress, meals: mealBubbles, isDark: isDark)
                                .id(consumedTabId)
                        }
                        .padding(.top, isIntakeCardExpanded ? 32 : 16)
                        .padding(.bottom, isIntakeCardExpanded ? 0 : 0)
                        .padding(.horizontal, isIntakeCardExpanded ? 0 : 0)

                        if isIntakeCardExpanded {
                            VStack(alignment: .leading, spacing: 16) {
                                // Orie Assist Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Orie Assist")
                                            .font(.system(size: 16))
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.primaryText(isDark))
                                        Text("Start to dig a little deeper")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.secondaryText(isDark))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $isOrieAssistEnabled)
                                        .labelsHidden()
                                }
                                .padding(.top, 42)

                                Text("Today's Macros")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .padding(.top, 24)
                                    .padding(.bottom, 8)

                                MacroAverageRow(
                                    color: Color(red: 49/255, green: 209/255, blue: 149/255),
                                    title: "Protein", value: consumedProtein, goal: vm.dailyProteinGoal, unit: "g",
                                    suggestion: isOrieAssistEnabled ? macroSuggestion(consumed: consumedProtein, goal: vm.dailyProteinGoal) : nil,
                                    isDark: isDark
                                )
                                MacroAverageRow(
                                    color: Color(red: 135/255, green: 206/255, blue: 250/255),
                                    title: "Carbs", value: consumedCarbs, goal: vm.dailyCarbsGoal, unit: "g",
                                    suggestion: isOrieAssistEnabled ? macroSuggestion(consumed: consumedCarbs, goal: vm.dailyCarbsGoal) : nil,
                                    isDark: isDark
                                )
                                MacroAverageRow(
                                    color: Color(red: 255/255, green: 180/255, blue: 50/255),
                                    title: "Fats", value: consumedFats, goal: vm.dailyFatsGoal, unit: "g",
                                    suggestion: isOrieAssistEnabled ? macroSuggestion(consumed: consumedFats, goal: vm.dailyFatsGoal) : nil,
                                    isDark: isDark
                                )

                                Text("Today's Nutrition")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .padding(.top, 24)
                                    .padding(.bottom, 8)

                                if vm.dailyFibreGoal > 0 {
                                    MacroAverageRow(
                                        color: Color(red: 160/255, green: 80/255, blue: 255/255),
                                        title: "Fibre", value: consumedFibre, goal: vm.dailyFibreGoal, unit: "g",
                                        suggestion: isOrieAssistEnabled ? nutritionSuggestion(consumed: consumedFibre, goal: vm.dailyFibreGoal) : nil,
                                        isDark: isDark
                                    )
                                } else {
                                    NutritionAverageRow(
                                        color: Color(red: 160/255, green: 80/255, blue: 255/255),
                                        title: "Fibre", value: consumedFibre, unit: "g", isDark: isDark
                                    )
                                }

                                if vm.dailySodiumGoal > 0 {
                                    MacroAverageRow(
                                        color: Color(red: 255/255, green: 105/255, blue: 180/255),
                                        title: "Sodium", value: consumedSodium, goal: vm.dailySodiumGoal, unit: "mg",
                                        suggestion: isOrieAssistEnabled ? nutritionSuggestion(consumed: consumedSodium, goal: vm.dailySodiumGoal) : nil,
                                        isDark: isDark
                                    )
                                } else {
                                    NutritionAverageRow(
                                        color: Color(red: 255/255, green: 105/255, blue: 180/255),
                                        title: "Sodium", value: consumedSodium, unit: "mg", isDark: isDark
                                    )
                                }

                                if vm.dailySugarGoal > 0 {
                                    MacroAverageRow(
                                        color: Color(red: 255/255, green: 30/255, blue: 60/255),
                                        title: "Sugar", value: consumedSugar, goal: vm.dailySugarGoal, unit: "g",
                                        suggestion: isOrieAssistEnabled ? nutritionSuggestion(consumed: consumedSugar, goal: vm.dailySugarGoal) : nil,
                                        isDark: isDark
                                    )
                                } else {
                                    NutritionAverageRow(
                                        color: Color(red: 255/255, green: 30/255, blue: 60/255),
                                        title: "Sugar", value: consumedSugar, unit: "g", isDark: isDark
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, isIntakeCardExpanded ? 32 : 22)
                    .padding(.horizontal, 24)
                    .padding(.bottom, isIntakeCardExpanded ? (isOrieAssistEnabled ? 32 : 40) : 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(isIntakeCardExpanded ? 32 : 32)
                    .overlay {
                        IntakeCardPulseOverlay(active: pulseIntakeCard, isDark: isDark)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isIntakeCardExpanded.toggle()
                        if showIntakeCardNudge {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showIntakeCardNudge = false
                            }
                            pulseIntakeCard = false
                        }
                    }

                    // Food entries + input
                    VStack(spacing: 0) {
                        if vm.hasAnyEntries == false && !isShowingFoodInput {
                            firstEntryCard
                        }

                        if (vm.hasAnyEntries ?? false) || isShowingFoodInput {
                        ForEach(entriesByPeriod, id: \.period) { group in
                            if isOrieAssistEnabled {
                                mealPeriodHeader(
                                    period: group.period,
                                    calories: group.entries.reduce(0) { $0 + ($1.calories ?? 0) }
                                )
                            }
                            ForEach(group.entries) { entry in
                                let isFirstEntry = !isOrieAssistEnabled && group.period == entriesByPeriod.first?.period && entry.id == group.entries.first?.id
                                FoodEntryRow(
                                    entry: entry,
                                    isDark: isDark,
                                    isOffline: !networkMonitor.isConnected,
                                    isFree: subscriptionManager.tier == .free,
                                    authManager: authManager,
                                    onTimeChange: { vm.updateEntryTime(entry.id, newTime: $0) },
                                    onDelete: { vm.deleteFoodEntry(entry) },
                                    onFoodNameChange: { vm.updateFoodEntry(entry.id, newFoodName: $0) },
                                    onNutritionChange: { vm.updateEntryNutrition(entry.id, calories: $0, protein: $1, carbs: $2, fats: $3) },
                                    onOpenSheet: { dismissAllInputs() },
                                    isEditing: Binding(
                                        get: { editingEntryId == entry.id },
                                        set: { isEditing in
                                            if isEditing { editingEntryId = entry.id }
                                            else if editingEntryId == entry.id { editingEntryId = nil }
                                        }
                                    )
                                )
                                .padding(.top, isFirstEntry ? 8 : 0)
                            }
                        }

                        FoodInputField(
                            text: $currentInput,
                            isDark: isDark,
                            onSubmit: { foodName in
                                let isFirstEverEntry = !hasShownFirstMealCelebration && vm.foodEntries.isEmpty
                                vm.addFoodEntry(foodName: foodName, date: selectedDate, isOffline: !networkMonitor.isConnected)
                                if isFirstEverEntry {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isInputFocused = false
                                    }
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation { proxy.scrollTo("inputField", anchor: .top) }
                                    }
                                }
                            },
                            onImageAnalyzed: { result in
                                vm.addFoodEntryFromImage(result: result, date: selectedDate)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation { proxy.scrollTo("inputField", anchor: .top) }
                                }
                            },
                            onError: { vm.showError($0) },
                            onPaywallRequired: { message in
                                subscriptionManager.paywallMessage = message
                                subscriptionManager.showUpgradePaywall = true
                            },
                            isFocused: $isInputFocused,
                            authManager: authManager,
                            onSuggestionChanged: { suggestion in
                                withAnimation(.easeInOut(duration: 0.2)) { autocompleteSuggestion = suggestion }
                            },
                            triggerRecording: $triggerMicFromNav,
                            triggerStopRecording: $triggerStopMicFromNav,
                            triggerCamera: $triggerCameraFromNav,
                            onRecordingChanged: { isRecordingFromField = $0 }
                        )
                        } // end if hasEverLoggedFood || isShowingFoodInput
                    }

                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)

                    if vm.hasAnyEntries == true && filteredEntries.isEmpty && !isShowingFoodInput {
                        lazyManCard
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - ❇️ Extracted Body Subviews

    private func mainListContent(proxy: ScrollViewProxy) -> some View {
        List {
            Color.clear
                .frame(height: 68)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            tabSelectorContent

            if selectedTab == "health" {
                HealthTabView(
                    consumedCalories: consumedCalories,
                    dailyCalorieGoal: vm.dailyCalorieGoal,
                    burnedCalories: 0,
                    consumedProtein: consumedProtein,
                    dailyProteinGoal: vm.dailyProteinGoal,
                    consumedCarbs: consumedCarbs,
                    dailyCarbsGoal: vm.dailyCarbsGoal,
                    consumedFats: consumedFats,
                    dailyFatsGoal: vm.dailyFatsGoal,
                    consumedFibre: consumedFibre,
                    dailyFibreGoal: vm.dailyFibreGoal,
                    consumedSodium: consumedSodium,
                    dailySodiumGoal: vm.dailySodiumGoal,
                    consumedSugar: consumedSugar,
                    dailySugarGoal: vm.dailySugarGoal,
                    meals: mealBubbles,
                    weeklyData: vm.weeklyMacroData,
                    weeklyNote: vm.weeklyNote,
                    isDark: isDark
                )
                .id(healthTabId)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            consumedTabContent(proxy: proxy)

            Color.clear
                .frame(height: 120)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .onChange(of: vm.foodEntries.count) { oldCount, newCount in
            if oldCount == 0 && newCount > 0 && !hasShownFirstMealCelebration {
                awaitingFirstEntryCalculation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { proxy.scrollTo("inputField", anchor: .top) }
            }
        }
        .onChange(of: isInputFocused) { _, isFocused in
            if !isFocused && vm.hasAnyEntries == false && vm.foodEntries.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) { isShowingFoodInput = false }
            }
        }
        .onChange(of: vm.hasAnyEntries) { _, newValue in
            if newValue == false {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingFoodInput = false
                    isInputFocused = false
                }
                hasShownFirstMealCelebration = false
                showIntakeCardNudge = false
                pulseIntakeCard = false
            }
        }
        .onChange(of: vm.foodEntries) { _, entries in
            guard awaitingFirstEntryCalculation,
                  let first = entries.first,
                  !first.isLoading,
                  first.calories != nil else { return }
            awaitingFirstEntryCalculation = false
            hasShownFirstMealCelebration = true
            showFirstMealCelebration = true
        }
        .onChange(of: shouldScrollToInput) { _, newValue in
            if newValue {
                withAnimation { proxy.scrollTo("inputField", anchor: .top) }
                shouldScrollToInput = false
            }
        }
    }

    private var topNavBarView: some View {
        TopNavigationBar(
            showAwards: $showAwards,
            showProfile: $showProfile,
            showSettings: $showSettings,
            showNotifications: $showNotifications,
            isDateSelectionMode: $isDateSelectionMode,
            selectedDate: $selectedDate,
            selectedTab: $selectedTab,
            isToday: isToday,
            isDark: isDark,
            isInputFocused: Binding(
                get: { isInputFocused || editingEntryId != nil },
                set: { newValue in
                    if !newValue {
                        if editingEntryId != nil { editingEntryId = nil }
                        isInputFocused = false
                    } else {
                        isInputFocused = newValue
                    }
                }
            ),
            hasUnreadNotifications: notificationManager.unreadCount > 0
        )
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appBackground(isDark), Color.appBackground(isDark).opacity(0)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .offset(y: -10)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .top)
        )
    }

    private var bottomFadeView: some View {
        VStack {
            Spacer()
            LinearGradient(
                gradient: Gradient(colors: [Color.appBackground(isDark).opacity(0), Color.appBackground(isDark)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder private var overlayBannersView: some View {
        if !networkMonitor.isConnected {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Offline · manual entries enabled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                #if os(iOS)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                #else
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                #endif
                .padding(.bottom, 36)
            }
            .ignoresSafeArea(.keyboard)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeOut(duration: 0.3), value: networkMonitor.isConnected)
            .zIndex(12)
        }

        if let errorMessage = vm.apiErrorMessage, networkMonitor.isConnected {
            VStack {
                Spacer()
                ErrorBanner(message: errorMessage)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(10)
        }

        if vm.showAiLimitAlert {
            VStack {
                Spacer()
                AiLimitBanner(
                    used: subscriptionManager.aiUsedToday,
                    limit: subscriptionManager.aiLimit,
                    isDark: isDark,
                    onUpgrade: {
                        vm.showAiLimitAlert = false
                        subscriptionManager.paywallMessage = "Upgrade to Premium for more daily AI entries."
                        subscriptionManager.showUpgradePaywall = true
                    },
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            vm.showAiLimitAlert = false
                        }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeOut(duration: 0.3), value: vm.showAiLimitAlert)
            .zIndex(10)
        }


        if showIntakeCardNudge {
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.primaryText(isDark))
                    Text("Tap the daily intake card to see your macros")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                #if os(iOS)
                .glassEffect(.regular.tint(Color.yellow.opacity(0.45)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                #else
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                #endif
                .padding(.bottom, 100)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeOut(duration: 0.3), value: showIntakeCardNudge)
            .zIndex(13)
            .ignoresSafeArea(.keyboard)
        }

        if let award = vm.awardBannerAchievement {
            VStack {
                Spacer()
                AwardBanner(achievement: award) { showAwards = true }
                    .padding(.horizontal, 20)
                    .padding(.bottom, vm.apiErrorMessage != nil ? 120 : 48)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(11)
        }
    }

    private var bottomNavBarView: some View {
        VStack {
            Spacer()
            BottomNavigationBar(
                isDark: isDark,
                isRecording: isRecordingFromField,
                onFocusInput: {
                    selectedTab = "consumed"
                    isInputFocused = true
                    shouldScrollToInput = true
                },
                onAskOrie: {
                    dismissAllInputs()
                    if subscriptionManager.tier == .premium {
                        showOrieChat = true
                    } else {
                        subscriptionManager.paywallMessage = "Orie's chat is reserved for premium members."
                        subscriptionManager.showUpgradePaywall = true
                    }
                },
                onTriggerMic: {
                    if isRecordingFromField {
                        triggerStopMicFromNav = true
                    } else {
                        selectedTab = "consumed"
                        shouldScrollToInput = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            triggerMicFromNav = true
                        }
                    }
                },
                onTriggerCamera: {
                    if subscriptionManager.tier != .premium {
                        subscriptionManager.paywallMessage = "Photo scanning is a premium feature. Upgrade to scan unlimited meals."
                        subscriptionManager.showUpgradePaywall = true
                    } else {
                        selectedTab = "consumed"
                        shouldScrollToInput = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            triggerCameraFromNav = true
                        }
                    }
                }
            )
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - ❇️ Body

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground(isDark).ignoresSafeArea()
            ScrollViewReader { proxy in mainListContent(proxy: proxy) }
            topNavBarView
            bottomFadeView
            overlayBannersView
            bottomNavBarView
            autocompletePillOverlay
            if subscriptionManager.showUpgradePaywall {
                UpgradePremiumModal()
                    .zIndex(20)
                    .transaction { $0.animation = nil }
            }
        }

        // MARK: - ❇️ Sheet Modifiers
        .sheet(isPresented: $showFirstMealCelebration, onDismiss: {
            showIntakeCardNudge = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pulseIntakeCard = true
            }
        }) {
            FirstMealCelebrationView {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showFirstMealCelebration = false
                isInputFocused = false
            }
            .presentationBackground(Color(red: 0x18/255, green: 0x18/255, blue: 0x18/255))
            .presentationDetents([.fraction(0.75)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAwards) {
            AwardSheet()
                .presentationBackground(Color.appBackground(isDark))
        }
        .sheet(isPresented: $showProfile, onDismiss: {
            vm.loadUserProfile()
        }) {
            ProfileSheet()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(localNotificationManager)
                .environmentObject(subscriptionManager)
                .presentationBackground(Color.appBackground(isDark))
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            vm.loadUserProfile()
        }) {
            SettingsSheet()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(localNotificationManager)
                .environmentObject(subscriptionManager)
                .presentationBackground(Color.appBackground(isDark))
        }
        .sheet(isPresented: $showNotifications) {
            NotificationSheet()
                .environmentObject(notificationManager)
                .environmentObject(themeManager)
                .presentationBackground(Color.appBackground(isDark))
        }
        .sheet(isPresented: $showOrieChat) {
            AskOrieModal(
                remainingCalories: remainingCalories,
                consumedCalories: consumedCalories,
                consumedProtein: consumedProtein,
                consumedCarbs: consumedCarbs,
                consumedFats: consumedFats,
                calorieGoal: vm.dailyCalorieGoal,
                proteinGoal: vm.dailyProteinGoal,
                carbsGoal: vm.dailyCarbsGoal,
                foodEntries: filteredEntries,
                onAddMeal: { suggestion in
                    vm.addFoodEntryFromChat(suggestion, date: selectedDate)
                }
            )
            .presentationBackground(Color.appBackground(isDark))
        }

        // MARK: - ❇️ Lifecycle Handlers
        .onAppear {
            vm.configure(authManager: authManager, localNotificationManager: localNotificationManager, networkMonitor: networkMonitor)
            vm.load(for: selectedDate)
            vm.checkHasAnyEntries()
        }
        .onChange(of: selectedDate) { _, _ in
            vm.loadFoodEntries(for: selectedDate)
        }
        .onChange(of: isInputFocused) { _, focused in
            if focused {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isDateSelectionMode = false }
            }
        }
        .onChange(of: editingEntryId) { _, id in
            if id != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isDateSelectionMode = false }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == "consumed" { consumedTabId = UUID() }
            else if newTab == "health" { healthTabId = UUID() }
        }
        .onChange(of: showAwards) { _, shown in if shown { dismissAllInputs() } }
        .onChange(of: showProfile) { _, shown in if shown { dismissAllInputs() } }
        .onChange(of: showSettings) { _, shown in if shown { dismissAllInputs() } }
        .onChange(of: showNotifications) { _, shown in if shown { dismissAllInputs() } }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            guard isConnected else { return }
            // First calculate pending entries (entries without calories)
            vm.calculatePendingEntries()
            // Then sync entries that already have calories
            vm.syncOfflineEntries()
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                vm.configure(authManager: authManager, localNotificationManager: localNotificationManager, networkMonitor: networkMonitor)
                vm.load(for: selectedDate)
            } else {
                vm.resetForSignOut()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = frame.cgRectValue.height }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
                autocompleteSuggestion = nil
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                vm.loadFoodEntries(for: selectedDate)
                vm.loadWeeklyFoodEntries()
                vm.checkHasAnyEntries()
                let today = DateFormatter.yyyyMMdd.string(from: Date())
                if today != vm.lastWeeklyProgressRefreshDate {
                    vm.lastWeeklyProgressRefreshDate = today
                    vm.loadWeeklyProgress(forceRefresh: true)
                } else {
                    vm.loadWeeklyProgress()
                }
            }
        }
    }
}

// MARK: - ❇️ Intake Card Pulse Overlay

private struct IntakeCardPulseOverlay: View {
    let active: Bool
    let isDark: Bool

    @State private var animating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .stroke(Color.accessibleYellow(isDark), lineWidth: 1.5)
            .opacity(animating ? 0.7 : 0)
            .onChange(of: active) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        animating = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animating = false
                    }
                }
            }
    }
}

// MARK: - ❇️ Date Formatter Helper
private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

#Preview("Default") {
    MainView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(NotificationManager())
        .environmentObject(LocalNotificationManager.shared)
        .environmentObject(SubscriptionManager())
}
