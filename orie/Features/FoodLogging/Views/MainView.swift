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
    @State private var showNotifications = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var selectedTab: String = "consumed"
    @State private var isDateSelectionMode = false
    @FocusState private var isInputFocused: Bool
    @State private var editingEntryId: UUID? = nil
    @State private var consumedTabId: UUID = UUID()
    @State private var healthTabId: UUID = UUID()
    @AppStorage("isIntakeCardExpanded") private var isIntakeCardExpanded: Bool = false
    @State private var autocompleteSuggestion: String? = nil
    @State private var keyboardHeight: CGFloat = 0

    // MARK: - ❇️ Computed Properties

    private var isDark: Bool { themeManager.isDarkMode }

    private var filteredEntries: [FoodEntry] {
        vm.foodEntries.filter { Calendar.current.isDate($0.entryDate, inSameDayAs: selectedDate) }
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
            .padding(.bottom, 40)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        } else {
            HStack(spacing: 32) {
                TabButton(title: "Health", isSelected: selectedTab == "health", isDark: isDark, action: { selectedTab = "health" })
                TabButton(title: "Consumed", isSelected: selectedTab == "consumed", isDark: isDark, action: { selectedTab = "consumed" })
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            .padding(.bottom, 40)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - ❇️ Consumed Tab Content

    @ViewBuilder
    private func consumedTabContent(proxy: ScrollViewProxy) -> some View {
        if selectedTab == "consumed" {
            VStack(spacing: 8) {
                if vm.isEntriesLoading {
                    ConsumedTabSkeleton(isDark: isDark)
                } else {
                    // Daily intake card
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Daily intake")
                            .font(.system(size: 12))
                            .foregroundColor(Color.secondaryText(isDark))
                            .fontWeight(.medium)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(consumedCalories.formatted())
                                .font(.system(size: 24))
                                .fontWeight(.semibold)
                                .foregroundColor(Color.primaryText(isDark))
                            Text("cal")
                                .font(.system(size: 14))
                                .foregroundColor(Color.primaryText(isDark))
                                .fontWeight(.regular)
                        }
                        .padding(.top, 4)

                        Text("\(remainingCalories) remaining")
                            .font(.system(size: 14))
                            .foregroundColor(remainingCalories < -100 ? .red : Color.accessibleYellow(isDark))
                            .padding(.top, 4)

                        VStack(spacing: 8) {
                            HStack {
                                Text("0")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.secondaryText(isDark))
                                Spacer()
                                Text(vm.dailyCalorieGoal.formatted())
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.primaryText(isDark))
                            }
                            MealProgressBar(progress: calorieProgress, meals: mealBubbles, isDark: isDark)
                                .id(consumedTabId)
                        }
                        .padding(.top, 32)

                        if isIntakeCardExpanded {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Today's Macros")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .padding(.bottom, 16)
                                    .padding(.top, 32)

                                MacroAverageRow(
                                    color: Color(red: 49/255, green: 209/255, blue: 149/255),
                                    title: "Protein", value: consumedProtein, goal: vm.dailyProteinGoal, unit: "g",
                                    suggestion: macroSuggestion(consumed: consumedProtein, goal: vm.dailyProteinGoal),
                                    isDark: isDark
                                )
                                MacroAverageRow(
                                    color: Color(red: 135/255, green: 206/255, blue: 250/255),
                                    title: "Carbs", value: consumedCarbs, goal: vm.dailyCarbsGoal, unit: "g",
                                    suggestion: macroSuggestion(consumed: consumedCarbs, goal: vm.dailyCarbsGoal),
                                    isDark: isDark
                                )
                                MacroAverageRow(
                                    color: Color(red: 255/255, green: 180/255, blue: 50/255),
                                    title: "Fats", value: consumedFats, goal: vm.dailyFatsGoal, unit: "g",
                                    suggestion: macroSuggestion(consumed: consumedFats, goal: vm.dailyFatsGoal),
                                    isDark: isDark
                                )

                                Text("Today's Nutrition")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .padding(.bottom, 8)
                                    .padding(.top, 16)

                                if vm.dailyFibreGoal > 0 {
                                    MacroAverageRow(
                                        color: Color(red: 160/255, green: 80/255, blue: 255/255),
                                        title: "Fibre", value: consumedFibre, goal: vm.dailyFibreGoal, unit: "g",
                                        suggestion: nutritionSuggestion(consumed: consumedFibre, goal: vm.dailyFibreGoal),
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
                                        suggestion: nutritionSuggestion(consumed: consumedSodium, goal: vm.dailySodiumGoal),
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
                                        suggestion: nutritionSuggestion(consumed: consumedSugar, goal: vm.dailySugarGoal),
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
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(32)
                    .contentShape(Rectangle())
                    .onTapGesture { isIntakeCardExpanded.toggle() }

                    // Food entries + input
                    VStack(spacing: 0) {
                        ForEach(filteredEntries.sorted()) { entry in
                            FoodEntryRow(
                                entry: entry,
                                isDark: isDark,
                                isOffline: !networkMonitor.isConnected,
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
                        }

                        FoodInputField(
                            text: $currentInput,
                            isDark: isDark,
                            onSubmit: { foodName in
                                vm.addFoodEntry(foodName: foodName, date: selectedDate, isOffline: !networkMonitor.isConnected)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation { proxy.scrollTo("inputField", anchor: .top) }
                                }
                            },
                            onImageAnalyzed: { result in
                                vm.addFoodEntryFromImage(result: result, date: selectedDate)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation { proxy.scrollTo("inputField", anchor: .top) }
                                }
                            },
                            onError: { vm.showError($0) },
                            isFocused: $isInputFocused,
                            authManager: authManager,
                            onSuggestionChanged: { suggestion in
                                withAnimation(.easeInOut(duration: 0.2)) { autocompleteSuggestion = suggestion }
                            }
                        )
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(32)
                }
            }
            .padding(.horizontal, 16)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - ❇️ Body

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: ❇️ Background
            Color.appBackground(isDark)
                .ignoresSafeArea()

            // MARK: ❇️ Main Scrollable Content
            ScrollViewReader { proxy in
                List {
                    Color.clear
                        .frame(height: 68)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    tabSelectorContent

                    // MARK: 👉 Health Tab
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

                    // MARK: 👉 Consumed Tab
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
                .onChange(of: vm.foodEntries.count) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo("inputField", anchor: .top) }
                    }
                }
            }

            // MARK: - ❇️ Floating Navigation Bar
            TopNavigationBar(
                showAwards: $showAwards,
                showProfile: $showProfile,
                showNotifications: $showNotifications,
                isDateSelectionMode: $isDateSelectionMode,
                selectedDate: $selectedDate,
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

            // MARK: - ❇️ Bottom Fade Overlay
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

            // MARK: - Offline Indicator
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

            // MARK: - ❇️ Error Banner
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

            // MARK: - ❇️ Award Banner
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

            // MARK: - ❇️ Autocomplete Pill
            autocompletePillOverlay
        }

        // MARK: - ❇️ Sheet Modifiers
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
        .sheet(isPresented: $showNotifications) {
            NotificationSheet()
                .environmentObject(notificationManager)
                .environmentObject(themeManager)
                .presentationBackground(Color.appBackground(isDark))
        }

        // MARK: - ❇️ Lifecycle Handlers
        .onAppear {
            vm.configure(authManager: authManager, localNotificationManager: localNotificationManager)
            vm.load(for: selectedDate)
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
        .onChange(of: showNotifications) { _, shown in if shown { dismissAllInputs() } }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            guard isConnected else { return }
            vm.syncOfflineEntries()
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                vm.configure(authManager: authManager, localNotificationManager: localNotificationManager)
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

// MARK: - ❇️ Date Formatter Helper
private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

#Preview {
    MainView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(NotificationManager())
        .environmentObject(LocalNotificationManager.shared)
}
