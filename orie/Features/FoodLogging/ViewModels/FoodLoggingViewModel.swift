//
//  FoodLoggingViewModel.swift
//  orie
//

import SwiftUI
import Combine
import ActivityKit

@MainActor
final class FoodLoggingViewModel: ObservableObject {

    // MARK: - ❇️ Dependencies

    private var authManager: AuthManager?
    private var localNotificationManager: LocalNotificationManager?

    // MARK: - ❇️ Published State

    @Published var foodEntries: [FoodEntry] = []
    @Published var weeklyFoodEntries: [FoodEntry] = []
    @Published var isEntriesLoading: Bool = true
    @Published var apiErrorMessage: String? = nil
    @Published var awardBannerAchievement: Achievement? = nil
    @Published var awardBannerQueue: [Achievement] = []
    @Published var dailyCalorieGoal: Int = 0
    @Published var dailyProteinGoal: Int = 0
    @Published var dailyCarbsGoal: Int = 0
    @Published var dailyFatsGoal: Int = 0
    @Published var dailySodiumGoal: Int = 0
    @Published var dailyFibreGoal: Int = 0
    @Published var dailySugarGoal: Int = 0
    @Published var weeklyNote: String = "Tap to see your weekly overview and daily averages."
    @Published var weeklyTip: String? = nil
    @Published var showUpgradePrompt: Bool = false

    @AppStorage("lastWeeklyProgressRefreshDate") var lastWeeklyProgressRefreshDate: String = ""

    // MARK: - ❇️ Private Task Handles

    private var errorBannerTask: Task<Void, Never>? = nil
    private var awardBannerTask: Task<Void, Never>? = nil

    // MARK: - ❇️ Weekly Data

    var currentWeekDates: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    var weeklyMacroData: [DailyMacroData] {
        let calendar = Calendar.current
        return currentWeekDates.map { date in
            let dayEntries = weeklyFoodEntries.filter { calendar.isDate($0.entryDate, inSameDayAs: date) }
            return DailyMacroData(
                date: date,
                calories: dayEntries.reduce(0) { $0 + ($1.calories ?? 0) },
                protein: Int(dayEntries.reduce(0.0) { $0 + ($1.protein ?? 0) }),
                carbs: Int(dayEntries.reduce(0.0) { $0 + ($1.carbs ?? 0) }),
                fats: Int(dayEntries.reduce(0.0) { $0 + ($1.fats ?? 0) }),
                fibre: Int(dayEntries.reduce(0.0) { $0 + ($1.fibre ?? 0) }),
                sodium: Int(dayEntries.reduce(0.0) { $0 + ($1.sodium ?? 0) }),
                sugar: Int(dayEntries.reduce(0.0) { $0 + ($1.sugar ?? 0) })
            )
        }
    }

    // MARK: - ❇️ Setup

    func configure(authManager: AuthManager, localNotificationManager: LocalNotificationManager) {
        self.authManager = authManager
        self.localNotificationManager = localNotificationManager
    }

    func load(for date: Date) {
        loadFoodEntries(for: date)
        loadWeeklyFoodEntries()
        loadUserProfile()
        loadWeeklyProgress()
    }

    // MARK: - ❇️ Calendar Helpers

    func datesInCurrentMonth() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now),
              let monthRange = calendar.range(of: .day, in: .month, for: now) else { return [] }
        return monthRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
        }
    }

    // MARK: - ❇️ Error Handling

    func handleNetworkError(_ error: Error, fallback: String) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                showError("No internet connection. Please check your network.")
            case .timedOut, .cannotConnectToHost, .networkConnectionLost:
                showError("Server unreachable. Please try again shortly.")
            default:
                showError(fallback)
            }
        } else {
            showError(fallback)
        }
    }

    func showError(_ message: String) {
        errorBannerTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            apiErrorMessage = message
        }
        errorBannerTask = Task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation(.easeOut(duration: 0.3)) {
                apiErrorMessage = nil
            }
        }
    }

    // MARK: - ❇️ Award Banners

    func showAwardBanners(_ achievements: [Achievement]) {
        awardBannerQueue.append(contentsOf: achievements)
        guard awardBannerAchievement == nil else { return }
        showNextAward()
    }

    private func showNextAward() {
        guard !awardBannerQueue.isEmpty else { return }
        let next = awardBannerQueue.removeFirst()
        awardBannerTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            awardBannerAchievement = next
        }
        awardBannerTask = Task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation(.easeOut(duration: 0.3)) {
                awardBannerAchievement = nil
            }
            showNextAward()
        }
    }

    // MARK: - ❇️ Add Entry

    func addFoodEntry(foodName: String, date: Date, isOffline: Bool) {
        guard !foodName.isEmpty else { return }

        // Check if this is the first entry of the day
        let isFirstEntryToday = isFirstEntryOfDay(for: date)

        var newEntry = FoodEntry(foodName: foodName, entryDate: date)

        if isOffline {
            newEntry.isLoading = false
            foodEntries.append(newEntry)

            // Trigger streak celebration for first entry
            if isFirstEntryToday {
                triggerStreakCelebration()
            }
            return
        }

        foodEntries.append(newEntry)

        // Trigger streak celebration for first entry
        if isFirstEntryToday {
            triggerStreakCelebration()
        }

        Task {
            guard let authManager else { return }
            do {
                let previousData = try await authManager.withAuthRetry { accessToken in
                    try await FoodHistoryService.findPreviousEntry(accessToken: accessToken, foodName: foodName)
                }

                var nutrition: APIService.NutritionResponse
                if let cached = previousData {
                    print("📦 Using cached nutrition for: \(foodName)")
                    nutrition = APIService.NutritionResponse(
                        foodName: foodName,
                        calories: cached.calories,
                        protein: cached.protein,
                        carbs: cached.carbs,
                        fats: cached.fats,
                        fibre: cached.fibre,
                        sodium: cached.sodium,
                        sugar: cached.sugar,
                        servingSize: cached.servingSize,
                        imageUrl: nil,
                        sources: nil
                    )
                } else {
                    print("🌐 Fetching fresh nutrition for: \(foodName)")
                    nutrition = try await authManager.withAuthRetry { accessToken in
                        try await APIService.getNutrition(for: foodName, accessToken: accessToken)
                    }
                }

                guard let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) else { return }

                foodEntries[index].calories = nutrition.calories
                foodEntries[index].protein = nutrition.protein
                foodEntries[index].carbs = nutrition.carbs
                foodEntries[index].fats = nutrition.fats
                foodEntries[index].fibre = nutrition.fibre
                foodEntries[index].sodium = nutrition.sodium
                foodEntries[index].sugar = nutrition.sugar
                foodEntries[index].servingSize = nutrition.servingSize
                foodEntries[index].imageUrl = nutrition.imageUrl
                foodEntries[index].sources = nutrition.sources
                foodEntries[index].isLoading = false

                let dbEntry = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[index])
                }

                foodEntries[index].dbId = dbEntry.id
                localNotificationManager?.scheduleMealNotification(for: foodEntries[index])
                loadWeeklyFoodEntries()

                // Update calorie progress activity
                updateCalorieProgressActivity()

                if let syncResult = try? await authManager.withAuthRetry({ accessToken in
                    try await AchievementService.syncAchievements(accessToken: accessToken)
                }), !syncResult.newlyUnlocked.isEmpty {
                    showAwardBanners(syncResult.newlyUnlocked)
                }

            } catch APIError.sessionExpired {
                // handled by withAuthRetry
            } catch APIError.upgradeRequired {
                // Free tier: keep the entry but save without nutrition (same as offline)
                guard let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) else { return }
                foodEntries[index].isLoading = false
                do {
                    let dbEntry = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[index])
                    }
                    foodEntries[index].dbId = dbEntry.id
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index])
                } catch {
                    print("Failed to save free tier entry: \(error)")
                }
            } catch APIError.aiLimitReached {
                withAnimation { foodEntries.removeAll { $0.id == newEntry.id } }
                showError("Daily AI limit reached. Resets at midnight.")
            } catch {
                print("Error: \(error)")
                if let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) {
                    foodEntries[index].isLoading = false
                    handleNetworkError(error, fallback: "Couldn't calculate calories for \"\(foodName)\". Please try again.")
                }
            }
        }
    }

    func addFoodEntryFromImage(result: APIService.ImageAnalysisResponse, date: Date) {
        // Check if this is the first entry of the day
        let isFirstEntryToday = isFirstEntryOfDay(for: date)

        var newEntry = FoodEntry(foodName: result.description, entryDate: date)
        newEntry.calories = result.nutrition.calories
        newEntry.protein = result.nutrition.protein
        newEntry.carbs = result.nutrition.carbs
        newEntry.fats = result.nutrition.fats
        newEntry.fibre = result.nutrition.fibre
        newEntry.sodium = result.nutrition.sodium
        newEntry.sugar = result.nutrition.sugar
        newEntry.servingSize = result.nutrition.servingSize
        newEntry.imageUrl = result.nutrition.imageUrl
        newEntry.sources = result.nutrition.sources
        newEntry.isLoading = false

        foodEntries.append(newEntry)

        // Trigger streak celebration for first entry
        if isFirstEntryToday {
            triggerStreakCelebration()
        }

        Task {
            guard let authManager else { return }
            do {
                let dbEntry = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: newEntry)
                }
                if let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) {
                    foodEntries[index].dbId = dbEntry.id
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index])
                    loadWeeklyFoodEntries()

                    // Update calorie progress activity
                    updateCalorieProgressActivity()
                }
            } catch APIError.sessionExpired {
            } catch {
                print("Error saving image-analyzed entry: \(error)")
                handleNetworkError(error, fallback: "Couldn't save your entry. Please try again.")
            }
        }
    }

    // MARK: - ❇️ Update / Delete

    func updateEntryTime(_ entryId: UUID, newTime: Date) {
        guard let index = foodEntries.firstIndex(where: { $0.id == entryId }),
              let dbId = foodEntries[index].dbId else { return }

        withAnimation { foodEntries[index].timestamp = newTime }
        localNotificationManager?.updateMealNotification(for: foodEntries[index])

        Task {
            guard let authManager else { return }
            do {
                try await authManager.withAuthRetry { accessToken in
                    _ = try await FoodEntryService.updateFoodEntry(accessToken: accessToken, id: dbId, timestamp: newTime)
                }
            } catch APIError.sessionExpired {
            } catch {
                print("Failed to update entry time: \(error)")
            }
        }
    }

    func updateFoodEntry(_ entryId: UUID, newFoodName: String) {
        guard let index = foodEntries.firstIndex(where: { $0.id == entryId }),
              let dbId = foodEntries[index].dbId else { return }

        withAnimation {
            foodEntries[index].foodName = newFoodName
            foodEntries[index].isLoading = true
        }

        Task {
            guard let authManager else { return }
            do {
                let nutrition = try await authManager.withAuthRetry { accessToken in
                    try await APIService.getNutrition(for: newFoodName, accessToken: accessToken)
                }
                foodEntries[index].calories = nutrition.calories
                foodEntries[index].protein = nutrition.protein
                foodEntries[index].carbs = nutrition.carbs
                foodEntries[index].fats = nutrition.fats
                foodEntries[index].fibre = nutrition.fibre
                foodEntries[index].sodium = nutrition.sodium
                foodEntries[index].sugar = nutrition.sugar
                foodEntries[index].servingSize = nutrition.servingSize
                foodEntries[index].imageUrl = nutrition.imageUrl
                foodEntries[index].sources = nutrition.sources
                foodEntries[index].isLoading = false

                try await authManager.withAuthRetry { accessToken in
                    _ = try await FoodEntryService.updateFoodEntry(accessToken: accessToken, id: dbId, entry: self.foodEntries[index])
                }
            } catch APIError.sessionExpired {
            } catch {
                print("Failed to update food entry: \(error)")
                foodEntries[index].isLoading = false
                handleNetworkError(error, fallback: "Couldn't update entry. Please try again.")
            }
        }
    }

    func deleteFoodEntry(_ entry: FoodEntry) {
        localNotificationManager?.cancelMealNotification(for: entry.id)
        withAnimation { foodEntries.removeAll { $0.id == entry.id } }

        guard let dbId = entry.dbId else { return }
        Task {
            guard let authManager else { return }
            do {
                try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.deleteFoodEntry(accessToken: accessToken, id: dbId)
                }
                loadFoodEntries(for: entry.entryDate)
                loadWeeklyFoodEntries()

                // Update calorie progress activity after deletion
                updateCalorieProgressActivity()
            } catch APIError.sessionExpired {
            } catch {
                print("Failed to delete entry: \(error)")
                handleNetworkError(error, fallback: "Couldn't delete entry. Please try again.")
            }
        }
    }

    func updateEntryNutrition(_ entryId: UUID, calories: Int, protein: Double, carbs: Double, fats: Double) {
        guard let index = foodEntries.firstIndex(where: { $0.id == entryId }) else { return }

        withAnimation {
            foodEntries[index].calories = calories
            foodEntries[index].protein = protein
            foodEntries[index].carbs = carbs
            foodEntries[index].fats = fats
        }

        let existingDbId = foodEntries[index].dbId

        Task {
            guard let authManager else { return }
            do {
                if let dbId = existingDbId {
                    try await authManager.withAuthRetry { accessToken in
                        _ = try await FoodEntryService.updateFoodEntry(accessToken: accessToken, id: dbId, entry: self.foodEntries[index])
                    }
                } else {
                    let dbEntry = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[index])
                    }
                    foodEntries[index].dbId = dbEntry.id
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index])
                }
                loadWeeklyFoodEntries()

                // Update calorie progress activity
                updateCalorieProgressActivity()
            } catch APIError.sessionExpired {
            } catch {
                print("Failed to update nutrition: \(error)")
                handleNetworkError(error, fallback: "Couldn't update nutrition. Please try again.")
            }
        }
    }

    // MARK: - ❇️ Data Loading

    func loadFoodEntries(for date: Date) {
        isEntriesLoading = true
        Task {
            guard let authManager else { return }
            do {
                let entries = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.getFoodEntries(accessToken: accessToken, date: date)
                }
                foodEntries = entries.map { dbEntry in
                    var entry = FoodEntry(foodName: dbEntry.foodName, entryDate: date)
                    entry.dbId = dbEntry.id
                    entry.calories = dbEntry.calories
                    entry.protein = dbEntry.protein
                    entry.carbs = dbEntry.carbs
                    entry.fats = dbEntry.fats
                    entry.fibre = dbEntry.fibre
                    entry.sodium = dbEntry.sodium
                    entry.sugar = dbEntry.sugar
                    entry.servingSize = dbEntry.servingSize
                    entry.isLoading = false
                    if let timestamp = ISO8601DateFormatter().date(from: dbEntry.timestamp) {
                        entry.timestamp = timestamp
                    }
                    return entry
                }
                isEntriesLoading = false
            } catch APIError.sessionExpired {
                isEntriesLoading = false
            } catch {
                print("Failed to load food entries: \(error)")
                isEntriesLoading = false
                handleNetworkError(error, fallback: "Couldn't load your entries. Please try again.")
            }
        }
    }

    func loadWeeklyFoodEntries() {
        Task {
            guard let authManager else { return }
            var allEntries: [FoodEntry] = []
            for date in currentWeekDates {
                do {
                    let entries = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.getFoodEntries(accessToken: accessToken, date: date)
                    }
                    let mapped = entries.map { dbEntry -> FoodEntry in
                        var entry = FoodEntry(foodName: dbEntry.foodName, entryDate: date)
                        entry.dbId = dbEntry.id
                        entry.calories = dbEntry.calories
                        entry.protein = dbEntry.protein
                        entry.carbs = dbEntry.carbs
                        entry.fats = dbEntry.fats
                        entry.fibre = dbEntry.fibre
                        entry.sodium = dbEntry.sodium
                        entry.sugar = dbEntry.sugar
                        entry.servingSize = dbEntry.servingSize
                        entry.isLoading = false
                        if let timestamp = ISO8601DateFormatter().date(from: dbEntry.timestamp) {
                            entry.timestamp = timestamp
                        }
                        return entry
                    }
                    allEntries.append(contentsOf: mapped)
                } catch APIError.sessionExpired {
                    return
                } catch {
                    print("Failed to load food entries for \(date): \(error)")
                }
            }
            weeklyFoodEntries = allEntries
        }
    }

    func loadWeeklyProgress(forceRefresh: Bool = false) {
        Task {
            guard let authManager else { return }
            do {
                let progress = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.getWeeklyProgress(accessToken: accessToken, forceRefresh: forceRefresh)
                }
                weeklyNote = progress.statement
                weeklyTip = progress.tip
            } catch APIError.sessionExpired {
            } catch {
                print("Failed to load weekly progress: \(error)")
            }
        }
    }

    func loadUserProfile() {
        Task {
            guard let authManager else { return }
            do {
                let profile = try await authManager.withAuthRetry { accessToken in
                    try await AuthService.getProfile(accessToken: accessToken)
                }
                dailyCalorieGoal = profile.dailyCalories ?? 0
                dailyProteinGoal = profile.dailyProtein ?? 0
                dailyCarbsGoal = profile.dailyCarbs ?? 0
                dailyFatsGoal = profile.dailyFats ?? 0
                dailySodiumGoal = profile.dailySodium ?? 0
                dailyFibreGoal = profile.dailyFibre ?? 0
                dailySugarGoal = profile.dailySugar ?? 0
            } catch APIError.sessionExpired {
            } catch {
                print("Failed to load user profile: \(error)")
                handleNetworkError(error, fallback: "Couldn't load your profile. Please try again.")
            }
        }
    }

    // MARK: - ❇️ Offline Sync

    func syncOfflineEntries() {
        let unsynced = foodEntries.filter { $0.dbId == nil && !$0.isLoading && $0.calories != nil }
        guard !unsynced.isEmpty else { return }
        Task {
            guard let authManager, let localNotificationManager else { return }
            for entry in unsynced {
                guard let index = foodEntries.firstIndex(where: { $0.id == entry.id }) else { continue }
                do {
                    let dbEntry = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[index])
                    }
                    foodEntries[index].dbId = dbEntry.id
                    localNotificationManager.scheduleMealNotification(for: foodEntries[index])
                } catch APIError.sessionExpired {
                    break
                } catch {
                    print("Failed to sync offline entry: \(error)")
                }
            }
            loadWeeklyFoodEntries()
        }
    }

    // MARK: - ❇️ Sign Out Reset

    func resetForSignOut() {
        foodEntries = []
        weeklyFoodEntries = []
        dailyCalorieGoal = 0
        dailyProteinGoal = 0
        dailyCarbsGoal = 0
        dailyFatsGoal = 0
        dailySodiumGoal = 0
        dailyFibreGoal = 0
        dailySugarGoal = 0
        weeklyNote = "Tap to see your weekly overview and daily averages."
        weeklyTip = nil
    }

    // MARK: - ❇️ Streak Live Activity

    /// Check if this is the first food entry logged today
    private func isFirstEntryOfDay(for date: Date) -> Bool {
        let calendar = Calendar.current
        let todayEntries = foodEntries.filter { calendar.isDate($0.entryDate, inSameDayAs: date) }
        return todayEntries.isEmpty
    }

    /// Trigger the streak celebration Live Activity
    private func triggerStreakCelebration() {
        if #available(iOS 16.1, *) {
            let currentStreak = StreakManager.shared.currentStreak
            // Only show if streak is greater than 0
            guard currentStreak > 0 else { return }
            StreakActivityManager.shared.startStreakCelebration(streakDays: currentStreak)
        }
    }

    /// Start or update the all-day calorie progress Live Activity
    private func updateCalorieProgressActivity() {
        guard #available(iOS 16.1, *) else { return }

        // Check if user has enabled the feature
        let isEnabled = UserDefaults.standard.bool(forKey: "calorieProgressActivityEnabled")
        // Default to true if not set (first time use)
        let shouldShow = UserDefaults.standard.object(forKey: "calorieProgressActivityEnabled") == nil ? true : isEnabled

        guard shouldShow else {
            // If disabled, end any running activity
            CalorieProgressActivityManager.shared.endCalorieTracking()
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayEntries = foodEntries.filter { calendar.isDate($0.entryDate, inSameDayAs: today) }

        // Calculate totals
        let consumedCalories = todayEntries.reduce(0) { $0 + ($1.calories ?? 0) }
        let consumedProtein = Int(todayEntries.reduce(0.0) { $0 + ($1.protein ?? 0) })
        let consumedCarbs = Int(todayEntries.reduce(0.0) { $0 + ($1.carbs ?? 0) })
        let consumedFats = Int(todayEntries.reduce(0.0) { $0 + ($1.fats ?? 0) })

        // Start or update the activity
        CalorieProgressActivityManager.shared.startCalorieTracking(
            consumedCalories: consumedCalories,
            goalCalories: dailyCalorieGoal,
            consumedProtein: consumedProtein,
            goalProtein: dailyProteinGoal,
            consumedCarbs: consumedCarbs,
            goalCarbs: dailyCarbsGoal,
            consumedFats: consumedFats,
            goalFats: dailyFatsGoal
        )
    }

}
