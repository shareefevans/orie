//
//  ContentView.swift
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
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - ❇️ UI State

    @State private var foodEntries: [FoodEntry] = []
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
    @State private var isIntakeCardExpanded: Bool = false
    @State private var isEntriesLoading: Bool = true

    // MARK: - ❇️ Default Daily Goals (from user profile)

    @State private var dailyCalorieGoal: Int = 2300
    @State private var dailyProteinGoal: Int = 150
    @State private var dailyCarbsGoal: Int = 250
    @State private var dailyFatsGoal: Int = 65
    @State private var dailySugarGoal: Int = 50

    // MARK: - ❇️ Computed Properties

    private var isDark: Bool { themeManager.isDarkMode }

    private var filteredEntries: [FoodEntry] {
        foodEntries.filter { entry in
            Calendar.current.isDate(entry.entryDate, inSameDayAs: selectedDate)
        }
    }

    private var consumedCalories: Int {
        filteredEntries.reduce(0) { total, entry in
            total + (entry.calories ?? 0)
        }
    }

    private var remainingCalories: Int {
        dailyCalorieGoal - consumedCalories
    }

    private var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return min(Double(consumedCalories) / Double(dailyCalorieGoal), 1.0)
    }

    private var consumedProtein: Int {
        Int(filteredEntries.reduce(0.0) { total, entry in
            total + (entry.protein ?? 0)
        })
    }

    private var consumedCarbs: Int {
        Int(filteredEntries.reduce(0.0) { total, entry in
            total + (entry.carbs ?? 0)
        })
    }

    private var consumedFats: Int {
        Int(filteredEntries.reduce(0.0) { total, entry in
            total + (entry.fats ?? 0)
        })
    }

    private var consumedSugar: Int {
        0
    }

    private var mealBubbles: [MealBubble] {
        filteredEntries
            .filter { !$0.isLoading }
            .map { entry in
                MealBubble(
                    timestamp: entry.timestamp,
                    protein: entry.protein ?? 0,
                    carbs: entry.carbs ?? 0,
                    fats: entry.fats ?? 0
                )
            }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - ❇️ Weekly Data for Overview Card
    private var currentWeekDates: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday is first day of week
        let today = calendar.startOfDay(for: Date())

        // Find the Monday of this week
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        // Days to subtract to get to Monday
        let daysFromMonday = (weekday + 5) % 7 // Converts so Monday = 0, Tuesday = 1, etc.
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }

        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private var weeklyMacroData: [DailyMacroData] {
        let calendar = Calendar.current
        return currentWeekDates.map { date in
            let dayEntries = weeklyFoodEntries.filter { entry in
                calendar.isDate(entry.entryDate, inSameDayAs: date)
            }
            let calories = dayEntries.reduce(0) { $0 + ($1.calories ?? 0) }
            let protein = Int(dayEntries.reduce(0.0) { $0 + ($1.protein ?? 0) })
            let carbs = Int(dayEntries.reduce(0.0) { $0 + ($1.carbs ?? 0) })
            let fats = Int(dayEntries.reduce(0.0) { $0 + ($1.fats ?? 0) })
            let sugars = 0 // TODO: Add sugar tracking

            return DailyMacroData(
                date: date,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                sugars: sugars
            )
        }
    }

    @State private var weeklyNote: String = "Tap to see your weekly overview and daily averages."
    @State private var weeklyTip: String? = nil
    @State private var weeklyFoodEntries: [FoodEntry] = []

    // MARK: - ❇️ Functions
    // MARK: 👉 Add Food Entry
    private func addFoodEntry(foodName: String) {
        guard !foodName.isEmpty else { return }

        let newEntry = FoodEntry(foodName: foodName, entryDate: selectedDate)
        foodEntries.append(newEntry)

        Task {
            do {
                // First, check if we've logged this food before
                let previousData = try await authManager.withAuthRetry { accessToken in
                    try await FoodHistoryService.findPreviousEntry(
                        accessToken: accessToken,
                        foodName: foodName
                    )
                }

                var nutrition: APIService.NutritionResponse

                if let cached = previousData {
                    // Use cached nutrition data
                    print("📦 Using cached nutrition for: \(foodName)")
                    nutrition = APIService.NutritionResponse(
                        foodName: foodName,
                        calories: cached.calories,
                        protein: cached.protein,
                        carbs: cached.carbs,
                        fats: cached.fats,
                        servingSize: cached.servingSize,
                        imageUrl: nil,
                        sources: nil
                    )
                } else {
                    // Fetch fresh nutrition data from API
                    print("🌐 Fetching fresh nutrition for: \(foodName)")
                    nutrition = try await APIService.getNutrition(for: foodName)
                }

                if let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) {
                    await MainActor.run {
                        foodEntries[index].calories = nutrition.calories
                        foodEntries[index].protein = nutrition.protein
                        foodEntries[index].carbs = nutrition.carbs
                        foodEntries[index].fats = nutrition.fats
                        foodEntries[index].servingSize = nutrition.servingSize
                        foodEntries[index].imageUrl = nutrition.imageUrl
                        foodEntries[index].sources = nutrition.sources
                        foodEntries[index].isLoading = false
                    }

                    let dbEntry = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.createFoodEntry(
                            accessToken: accessToken,
                            entry: foodEntries[index]
                        )
                    }

                    await MainActor.run {
                        foodEntries[index].dbId = dbEntry.id
                        localNotificationManager.scheduleMealNotification(for: foodEntries[index])
                        loadWeeklyFoodEntries()
                    }
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Error: \(error)")
                if let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) {
                    await MainActor.run {
                        foodEntries[index].isLoading = false
                    }
                }
            }
        }
    }

    // MARK: 👉 addFoodEntryFromImage
    private func addFoodEntryFromImage(result: APIService.ImageAnalysisResponse) {
        var newEntry = FoodEntry(foodName: result.description, entryDate: selectedDate)
        newEntry.calories = result.nutrition.calories
        newEntry.protein = result.nutrition.protein
        newEntry.carbs = result.nutrition.carbs
        newEntry.fats = result.nutrition.fats
        newEntry.servingSize = result.nutrition.servingSize
        newEntry.imageUrl = result.nutrition.imageUrl
        newEntry.sources = result.nutrition.sources
        newEntry.isLoading = false

        foodEntries.append(newEntry)

        Task {
            do {
                let dbEntry = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.createFoodEntry(
                        accessToken: accessToken,
                        entry: newEntry
                    )
                }

                if let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) {
                    await MainActor.run {
                        foodEntries[index].dbId = dbEntry.id
                        // Schedule meal reminder notification
                        localNotificationManager.scheduleMealNotification(for: foodEntries[index])
                        // Refresh weekly data
                        loadWeeklyFoodEntries()
                    }
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Error saving image-analyzed entry: \(error)")
            }
        }
    }

    // MARK: 👉 UpdateEntryTime
    private func updateEntryTime(_ entryId: UUID, newTime: Date) {
        guard let index = foodEntries.firstIndex(where: { $0.id == entryId }),
              let dbId = foodEntries[index].dbId else { return }

        withAnimation {
            foodEntries[index].timestamp = newTime
        }

        // Update the meal reminder notification with new time
        localNotificationManager.updateMealNotification(for: foodEntries[index])

        Task {
            do {
                try await authManager.withAuthRetry { accessToken in
                    _ = try await FoodEntryService.updateFoodEntry(
                        accessToken: accessToken,
                        id: dbId,
                        timestamp: newTime
                    )
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Failed to update entry time: \(error)")
            }
        }
    }

    // MARK: 👉 UpdateFoodEntry
    private func updateFoodEntry(_ entryId: UUID, newFoodName: String) {
        guard let index = foodEntries.firstIndex(where: { $0.id == entryId }),
              let dbId = foodEntries[index].dbId else { return }

        withAnimation {
            foodEntries[index].foodName = newFoodName
            foodEntries[index].isLoading = true
        }

        Task {
            do {
                let nutrition = try await APIService.getNutrition(for: newFoodName)

                await MainActor.run {
                    foodEntries[index].calories = nutrition.calories
                    foodEntries[index].protein = nutrition.protein
                    foodEntries[index].carbs = nutrition.carbs
                    foodEntries[index].fats = nutrition.fats
                    foodEntries[index].servingSize = nutrition.servingSize
                    foodEntries[index].imageUrl = nutrition.imageUrl
                    foodEntries[index].sources = nutrition.sources
                    foodEntries[index].isLoading = false
                }

                try await authManager.withAuthRetry { accessToken in
                    _ = try await FoodEntryService.updateFoodEntry(
                        accessToken: accessToken,
                        id: dbId,
                        entry: foodEntries[index]
                    )
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Failed to update food entry: \(error)")
                await MainActor.run {
                    foodEntries[index].isLoading = false
                }
            }
        }
    }

    // MARK: 👉 DeleteFoodEntry
    private func deleteFoodEntry(_ entry: FoodEntry) {
        // Cancel the meal reminder notification
        localNotificationManager.cancelMealNotification(for: entry.id)

        withAnimation {
            foodEntries.removeAll { $0.id == entry.id }
        }

        if let dbId = entry.dbId {
            Task {
                do {
                    try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.deleteFoodEntry(
                            accessToken: accessToken,
                            id: dbId
                        )
                    }
                    loadFoodEntries()
                    loadWeeklyFoodEntries()
                } catch APIError.sessionExpired {
                    // Already handled by withAuthRetry - user is logged out
                } catch {
                    print("Failed to delete entry: \(error)")
                }
            }
        }
    }

    // MARK: 👉 UpdateEntryNutrition
    private func updateEntryNutrition(_ entryId: UUID, calories: Int, protein: Double, carbs: Double, fats: Double) {
        guard let index = foodEntries.firstIndex(where: { $0.id == entryId }),
              let dbId = foodEntries[index].dbId else { return }

        // Update local state immediately
        withAnimation {
            foodEntries[index].calories = calories
            foodEntries[index].protein = protein
            foodEntries[index].carbs = carbs
            foodEntries[index].fats = fats
        }

        // Persist to database
        Task {
            do {
                try await authManager.withAuthRetry { accessToken in
                    _ = try await FoodEntryService.updateFoodEntry(
                        accessToken: accessToken,
                        id: dbId,
                        entry: foodEntries[index]
                    )
                }
                loadWeeklyFoodEntries()
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Failed to update nutrition: \(error)")
            }
        }
    }

    // MARK: 👉 loadUserProfile
    private func loadUserProfile() {
        Task {
            do {
                let profile = try await authManager.withAuthRetry { accessToken in
                    try await AuthService.getProfile(accessToken: accessToken)
                }
                await MainActor.run {
                    if let calories = profile.dailyCalories, calories > 0 {
                        dailyCalorieGoal = calories
                    }
                    if let protein = profile.dailyProtein, protein > 0 {
                        dailyProteinGoal = protein
                    }
                    if let carbs = profile.dailyCarbs, carbs > 0 {
                        dailyCarbsGoal = carbs
                    }
                    if let fats = profile.dailyFats, fats > 0 {
                        dailyFatsGoal = fats
                    }
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Failed to load user profile: \(error)")
            }
        }
    }

    // MARK: 👉 loadFoodEntries
    private func loadFoodEntries() {
        isEntriesLoading = true
        Task {
            do {
                let entries = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.getFoodEntries(
                        accessToken: accessToken,
                        date: selectedDate
                    )
                }

                await MainActor.run {
                    foodEntries = entries.map { dbEntry in
                        var entry = FoodEntry(foodName: dbEntry.foodName, entryDate: selectedDate)
                        entry.dbId = dbEntry.id
                        entry.calories = dbEntry.calories
                        entry.protein = dbEntry.protein
                        entry.carbs = dbEntry.carbs
                        entry.fats = dbEntry.fats
                        entry.servingSize = dbEntry.servingSize
                        entry.isLoading = false

                        if let timestamp = ISO8601DateFormatter().date(from: dbEntry.timestamp) {
                            entry.timestamp = timestamp
                        }

                        return entry
                    }
                    isEntriesLoading = false
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
                await MainActor.run { isEntriesLoading = false }
            } catch {
                print("Failed to load food entries: \(error)")
                await MainActor.run { isEntriesLoading = false }
            }
        }
    }

    // MARK: 👉 loadWeeklyFoodEntries
    private func loadWeeklyFoodEntries() {
        Task {
            var allEntries: [FoodEntry] = []

            for date in currentWeekDates {
                do {
                    let entries = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.getFoodEntries(
                            accessToken: accessToken,
                            date: date
                        )
                    }

                    let mappedEntries = entries.map { dbEntry -> FoodEntry in
                        var entry = FoodEntry(foodName: dbEntry.foodName, entryDate: date)
                        entry.dbId = dbEntry.id
                        entry.calories = dbEntry.calories
                        entry.protein = dbEntry.protein
                        entry.carbs = dbEntry.carbs
                        entry.fats = dbEntry.fats
                        entry.servingSize = dbEntry.servingSize
                        entry.isLoading = false

                        if let timestamp = ISO8601DateFormatter().date(from: dbEntry.timestamp) {
                            entry.timestamp = timestamp
                        }

                        return entry
                    }

                    allEntries.append(contentsOf: mappedEntries)
                } catch APIError.sessionExpired {
                    // Already handled by withAuthRetry - user is logged out
                    return
                } catch {
                    print("Failed to load food entries for \(date): \(error)")
                }
            }

            await MainActor.run {
                weeklyFoodEntries = allEntries
            }
        }
    }

    // MARK: 👉 loadWeeklyProgress
    private func loadWeeklyProgress(forceRefresh: Bool = false) {
        Task {
            do {
                let progress = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.getWeeklyProgress(
                        accessToken: accessToken,
                        forceRefresh: forceRefresh
                    )
                }
                await MainActor.run {
                    weeklyNote = progress.statement
                    weeklyTip = progress.tip
                }
            } catch APIError.sessionExpired {
                // Already handled by withAuthRetry - user is logged out
            } catch {
                print("Failed to load weekly progress: \(error)")
            }
        }
    }

    // MARK: 👉 datesInCurrentMonth
    private func datesInCurrentMonth() -> [Date] {
        let calendar = Calendar.current
        let now = Date()

        guard let monthInterval = calendar.dateInterval(of: .month, for: now),
              let monthRange = calendar.range(of: .day, in: .month, for: now) else {
            return []
        }

        return monthRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
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

                    // MARK: 👉 Tab Buttons / Date Selector
                    if isDateSelectionMode {
                        ScrollViewReader { dateProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 24) {
                                    ForEach(datesInCurrentMonth(), id: \.self) { date in
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
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .black]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 32)

                                    Color.black

                                    LinearGradient(
                                        gradient: Gradient(colors: [.black, .clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 32)
                                }
                            )
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        dateProxy.scrollTo(selectedDate, anchor: .center)
                                    }
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
                            TabButton(
                                title: "Health",
                                isSelected: selectedTab == "health",
                                isDark: isDark,
                                action: { selectedTab = "health" }
                            )

                            TabButton(
                                title: "Consumed",
                                isSelected: selectedTab == "consumed",
                                isDark: isDark,
                                action: { selectedTab = "consumed" }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    // MARK: 👉 Health Tab
                    if selectedTab == "health" {
                        HealthTabView(
                            consumedCalories: consumedCalories,
                            dailyCalorieGoal: dailyCalorieGoal,
                            burnedCalories: 0,
                            consumedProtein: consumedProtein,
                            dailyProteinGoal: dailyProteinGoal,
                            consumedCarbs: consumedCarbs,
                            dailyCarbsGoal: dailyCarbsGoal,
                            consumedFats: consumedFats,
                            dailyFatsGoal: dailyFatsGoal,
                            consumedSugar: consumedSugar,
                            dailySugarGoal: dailySugarGoal,
                            meals: mealBubbles,
                            weeklyData: weeklyMacroData,
                            weeklyNote: weeklyNote,
                            isDark: isDark
                        )
                        .id(healthTabId)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    // MARK: 👉 Consumed Tab
                    if selectedTab == "consumed" {
                        VStack(spacing: 8) {

                            if isEntriesLoading {
                                ConsumedTabSkeleton(isDark: isDark)
                            } else {
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

                                            Text(dailyCalorieGoal.formatted())
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.primaryText(isDark))
                                        }

                                        MealProgressBar(
                                            progress: calorieProgress,
                                            meals: mealBubbles,
                                            isDark: isDark
                                        )
                                        .id(consumedTabId)
                                    }
                                    .padding(.top, 32)

                                    // Expandable macros section
                                    if isIntakeCardExpanded {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Today's Macros")
                                                .font(.system(size: 16))
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.primaryText(isDark))
                                                .padding(.bottom, 8)
                                                .padding(.top, 40)

                                            // Protein row
                                            HStack {
                                                Circle()
                                                    .fill(Color(red: 49/255, green: 209/255, blue: 149/255))
                                                    .frame(width: 8, height: 8)
                                                Text("Protein")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.primaryText(isDark))
                                                Spacer()
                                                Text("\(consumedProtein)g")
                                                    .font(.system(size: 12))
                                                    .fontWeight(.regular)
                                                    .foregroundColor(Color.primaryText(isDark))
                                                    .italic()
                                            }

                                            // Carbs row
                                            HStack {
                                                Circle()
                                                    .fill(Color(red: 135/255, green: 206/255, blue: 250/255))
                                                    .frame(width: 8, height: 8)
                                                Text("Carbs")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.primaryText(isDark))
                                                Spacer()
                                                Text("\(consumedCarbs)g")
                                                    .font(.system(size: 12))
                                                    .fontWeight(.regular)
                                                    .foregroundColor(Color.primaryText(isDark))
                                                    .italic()
                                            }

                                            // Fats row
                                            HStack {
                                                Circle()
                                                    .fill(Color(red: 255/255, green: 180/255, blue: 50/255))
                                                    .frame(width: 8, height: 8)
                                                Text("Fats")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.primaryText(isDark))
                                                Spacer()
                                                Text("\(consumedFats)g")
                                                    .font(.system(size: 12))
                                                    .fontWeight(.regular)
                                                    .foregroundColor(Color.primaryText(isDark))
                                                    .italic()
                                            }

                                            // Sugars row
                                            HStack {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 8, height: 8)
                                                Text("Sugars")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.primaryText(isDark))
                                                Spacer()
                                                Text("\(consumedSugar)g")
                                                    .font(.system(size: 12))
                                                    .fontWeight(.regular)
                                                    .foregroundColor(Color.primaryText(isDark))
                                                    .italic()
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
                                .onTapGesture {
                                    isIntakeCardExpanded.toggle()
                                }

                                VStack(spacing: 0) {
                                    // MARK: 👉 Food Entry Row
                                    ForEach(filteredEntries.sorted()) { entry in
                                        FoodEntryRow(
                                            entry: entry,
                                            isDark: isDark,
                                            onTimeChange: { newTime in
                                                updateEntryTime(entry.id, newTime: newTime)
                                            },
                                            onDelete: {
                                                deleteFoodEntry(entry)
                                            },
                                            onFoodNameChange: { newFoodName in
                                                updateFoodEntry(entry.id, newFoodName: newFoodName)
                                            },
                                            onNutritionChange: { calories, protein, carbs, fats in
                                                updateEntryNutrition(entry.id, calories: calories, protein: protein, carbs: carbs, fats: fats)
                                            },
                                            isEditing: Binding(
                                                get: { editingEntryId == entry.id },
                                                set: { isEditing in
                                                    if isEditing {
                                                        editingEntryId = entry.id
                                                    } else if editingEntryId == entry.id {
                                                        editingEntryId = nil
                                                    }
                                                }
                                            )
                                        )
                                    }

                                    // MARK: 👉 Food Input Field
                                    FoodInputField(
                                        text: $currentInput,
                                        isDark: isDark,
                                        onSubmit: { foodName in
                                            addFoodEntry(foodName: foodName)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation {
                                                    proxy.scrollTo("inputField", anchor: .top)
                                                }
                                            }
                                        },
                                        onImageAnalyzed: { result in
                                            addFoodEntryFromImage(result: result)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation {
                                                    proxy.scrollTo("inputField", anchor: .top)
                                                }
                                            }
                                        },
                                        isFocused: $isInputFocused,
                                        authManager: authManager
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

                    Color.clear
                        .frame(height: 120)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .onChange(of: foodEntries.count) { oldValue, newValue in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("inputField", anchor: .top)
                        }
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
                            if editingEntryId != nil {
                                editingEntryId = nil
                            }
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
                    gradient: Gradient(colors: [
                        Color.appBackground(isDark),
                        Color.appBackground(isDark).opacity(0),
                    ]),
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
                    gradient: Gradient(colors: [
                        Color.appBackground(isDark).opacity(0),
                        Color.appBackground(isDark)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)
        }

        // MARK: - ❇️ Sheet Modifiers
        .sheet(isPresented: $showAwards) {
            AwardSheet()
                .presentationBackground(Color.appBackground(isDark))
        }
        .sheet(isPresented: $showProfile, onDismiss: {
            loadUserProfile()
        }) {
            ProfileSheet()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(localNotificationManager)
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
            loadFoodEntries()
            loadWeeklyFoodEntries()
            loadUserProfile()
            loadWeeklyProgress()
        }
        .onChange(of: selectedDate) { _, _ in
            loadFoodEntries()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == "consumed" {
                consumedTabId = UUID()
            } else if newTab == "health" {
                healthTabId = UUID()
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                loadFoodEntries()
                loadWeeklyFoodEntries()
                loadUserProfile()
                loadWeeklyProgress()
            } else {
                foodEntries = []
                weeklyFoodEntries = []
                dailyCalorieGoal = 2300
                dailyProteinGoal = 150
                dailyCarbsGoal = 250
                dailyFatsGoal = 65
                dailySugarGoal = 50
                weeklyNote = "Tap to see your weekly overview and daily averages."
                weeklyTip = nil
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                loadFoodEntries()
                loadWeeklyFoodEntries()
                loadWeeklyProgress()
            }
        }
    }
}

// MARK: - ❇️ Consumed Tab Skeleton
struct ConsumedTabSkeleton: View {
    let isDark: Bool
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            // Daily Intake card skeleton
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 22)
                    .padding(.top, 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 12)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 10)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 10)
                    }

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                }
                .padding(.top, 32)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground(isDark))
            .cornerRadius(32)

            // Entry rows skeleton
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 14)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 14)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground(isDark))
            .cornerRadius(32)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(NotificationManager())
        .environmentObject(LocalNotificationManager.shared)
}
