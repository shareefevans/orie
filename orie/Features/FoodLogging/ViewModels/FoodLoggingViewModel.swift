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
    private var networkMonitor: NetworkMonitor?

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
    @Published var showAiLimitAlert: Bool = false
    @Published var hasAnyEntries: Bool? = nil
    @Published var currentStreak: Int = StreakManager.shared.currentStreak

    @AppStorage("lastWeeklyProgressRefreshDate") var lastWeeklyProgressRefreshDate: String = ""
    @AppStorage("aiLimitAlertShownDate") private var aiLimitAlertShownDate: String = ""

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

    func configure(authManager: AuthManager, localNotificationManager: LocalNotificationManager, networkMonitor: NetworkMonitor) {
        self.authManager = authManager
        self.localNotificationManager = localNotificationManager
        self.networkMonitor = networkMonitor
    }

    /// Get the current user's first name for notifications
    private var userName: String? {
        guard let fullName = authManager?.currentUser?.userMetadata?.fullName else { return nil }
        // Extract first name from full name
        return fullName.components(separatedBy: " ").first
    }

    func load(for date: Date) {
        loadFoodEntries(for: date)
        loadWeeklyFoodEntries()
        loadUserProfile()
        loadWeeklyProgress()
        refreshStreak()
    }

    func refreshStreak() {
        Task {
            guard let authManager = authManager else { return }
            do {
                let streak = try await authManager.withAuthRetry { accessToken in
                    try await APIService.getStreak(accessToken: accessToken)
                }
                await MainActor.run {
                    StreakManager.shared.update(to: streak)
                    self.currentStreak = streak
                }
            } catch {
                // Fall back to cached value silently
            }
        }
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
                localNotificationManager?.scheduleMealNotification(for: foodEntries[index], userName: userName)
                loadWeeklyFoodEntries()
                hasAnyEntries = true

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
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index], userName: userName)
                } catch {
                    print("Failed to save free tier entry: \(error)")
                }
                let todayString = Calendar.current.startOfDay(for: Date()).ISO8601Format()
                if aiLimitAlertShownDate != todayString {
                    aiLimitAlertShownDate = todayString
                    showAiLimitAlert = true
                }
            } catch APIError.aiLimitReached {
                // Save entry without nutrition (same as offline) so it shows "Add" button
                guard let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) else { return }
                foodEntries[index].isLoading = false
                do {
                    let dbEntry = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[index])
                    }
                    foodEntries[index].dbId = dbEntry.id
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index], userName: userName)
                } catch {
                    print("Failed to save AI limit entry: \(error)")
                }
                let todayString = Calendar.current.startOfDay(for: Date()).ISO8601Format()
                if aiLimitAlertShownDate != todayString {
                    aiLimitAlertShownDate = todayString
                    showAiLimitAlert = true
                }
            } catch {
                print("Error: \(error)")
                if let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) {
                    foodEntries[index].isLoading = false
                    // Only show error if we're online - offline banner already informs user
                    if networkMonitor?.isConnected ?? true {
                        handleNetworkError(error, fallback: "Couldn't calculate calories for \"\(foodName)\". Please try again.")
                    }
                }
            }
        }
    }

    private var pendingImageEntryId: UUID? = nil

    func beginImageEntry(date: Date) {
        var placeholder = FoodEntry(foodName: "Analysing photo…", entryDate: date)
        placeholder.isLoading = true
        pendingImageEntryId = placeholder.id
        foodEntries.append(placeholder)
    }

    func addFoodEntryFromImage(result: APIService.ImageAnalysisResponse, date: Date) {
        // Resolve which entry to update/append and whether it's the first today
        let entryId: UUID
        let isFirstEntryToday: Bool

        if let pendingId = pendingImageEntryId,
           let idx = foodEntries.firstIndex(where: { $0.id == pendingId }) {
            let othersTodayCount = foodEntries.filter {
                Calendar.current.isDate($0.entryDate, inSameDayAs: date) && $0.id != pendingId
            }.count
            isFirstEntryToday = othersTodayCount == 0
            foodEntries[idx].foodName = result.description
            foodEntries[idx].calories = result.nutrition.calories
            foodEntries[idx].protein = result.nutrition.protein
            foodEntries[idx].carbs = result.nutrition.carbs
            foodEntries[idx].fats = result.nutrition.fats
            foodEntries[idx].fibre = result.nutrition.fibre
            foodEntries[idx].sodium = result.nutrition.sodium
            foodEntries[idx].sugar = result.nutrition.sugar
            foodEntries[idx].servingSize = result.nutrition.servingSize
            foodEntries[idx].imageUrl = result.nutrition.imageUrl
            foodEntries[idx].sources = result.nutrition.sources
            foodEntries[idx].isLoading = false
            entryId = pendingId
            pendingImageEntryId = nil
        } else {
            isFirstEntryToday = isFirstEntryOfDay(for: date)
            var entry = FoodEntry(foodName: result.description, entryDate: date)
            entry.calories = result.nutrition.calories
            entry.protein = result.nutrition.protein
            entry.carbs = result.nutrition.carbs
            entry.fats = result.nutrition.fats
            entry.fibre = result.nutrition.fibre
            entry.sodium = result.nutrition.sodium
            entry.sugar = result.nutrition.sugar
            entry.servingSize = result.nutrition.servingSize
            entry.imageUrl = result.nutrition.imageUrl
            entry.sources = result.nutrition.sources
            entry.isLoading = false
            entryId = entry.id
            foodEntries.append(entry)
        }

        if isFirstEntryToday {
            triggerStreakCelebration()
        }

        Task {
            guard let authManager,
                  let idx = foodEntries.firstIndex(where: { $0.id == entryId }) else { return }
            do {
                let dbEntry = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[idx])
                }
                if let index = foodEntries.firstIndex(where: { $0.id == entryId }) {
                    foodEntries[index].dbId = dbEntry.id
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index], userName: userName)
                    loadWeeklyFoodEntries()
                    hasAnyEntries = true
                    updateCalorieProgressActivity()
                }
            } catch APIError.sessionExpired {
            } catch {
                print("Error saving image-analyzed entry: \(error)")
                handleNetworkError(error, fallback: "Couldn't save your entry. Please try again.")
            }
        }
    }

    func addFoodEntryFromChat(_ suggestion: MealSuggestion, date: Date) {
        let isFirstEntryToday = isFirstEntryOfDay(for: date)

        var newEntry = FoodEntry(foodName: suggestion.foodName, entryDate: date)
        newEntry.calories = suggestion.calories
        newEntry.protein = suggestion.protein
        newEntry.carbs = suggestion.carbs
        newEntry.fats = suggestion.fats
        newEntry.servingSize = suggestion.servingSize
        newEntry.isLoading = false

        foodEntries.append(newEntry)

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
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index], userName: userName)
                    loadWeeklyFoodEntries()
                    hasAnyEntries = true
                    updateCalorieProgressActivity()
                }
            } catch APIError.sessionExpired {
            } catch {
                handleNetworkError(error, fallback: "Couldn't save your entry. Please try again.")
            }
        }
    }

    // MARK: - ❇️ Update / Delete

    func updateEntryTime(_ entryId: UUID, newTime: Date) {
        guard let index = foodEntries.firstIndex(where: { $0.id == entryId }),
              let dbId = foodEntries[index].dbId else { return }

        withAnimation { foodEntries[index].timestamp = newTime }
        localNotificationManager?.updateMealNotification(for: foodEntries[index], userName: userName)

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
                checkHasAnyEntries()

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
                    localNotificationManager?.scheduleMealNotification(for: foodEntries[index], userName: userName)
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

    func checkHasAnyEntries() {
        Task {
            guard let authManager else { return }
            do {
                let result = try await authManager.withAuthRetry { accessToken in
                    try await FoodEntryService.hasAnyEntries(accessToken: accessToken)
                }
                await MainActor.run { hasAnyEntries = result }
            } catch {
                await MainActor.run { hasAnyEntries = false }
            }
        }
    }

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
                    entry.imageUrl = dbEntry.imageUrl
                    entry.sources = dbEntry.sources
                    entry.isLoading = false
                    if let timestamp = ISO8601DateFormatter().date(from: dbEntry.timestamp) {
                        entry.timestamp = timestamp
                    }
                    return entry
                }
                isEntriesLoading = false

                // Restart Live Activity if dismissed for today
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                if calendar.isDate(date, inSameDayAs: today) {
                    updateCalorieProgressActivity()
                }
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
                        entry.imageUrl = dbEntry.imageUrl
                        entry.sources = dbEntry.sources
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
                    localNotificationManager.scheduleMealNotification(for: foodEntries[index], userName: userName)
                } catch APIError.sessionExpired {
                    break
                } catch {
                    print("Failed to sync offline entry: \(error)")
                }
            }
            loadWeeklyFoodEntries()
        }
    }

    /// Calculate calories for entries that were added offline without manual nutrition data
    func calculatePendingEntries() {
        // Find entries that need calorie calculation (added offline without manual calories)
        let pending = foodEntries.filter { $0.calories == nil && $0.dbId == nil && !$0.isLoading }
        guard !pending.isEmpty else { return }

        print("📊 Auto-calculating \(pending.count) pending entries...")

        Task {
            guard let authManager, let localNotificationManager else { return }

            // Process entries one by one in order
            for entry in pending {
                guard let index = foodEntries.firstIndex(where: { $0.id == entry.id }) else { continue }

                // Set loading state
                foodEntries[index].isLoading = true

                do {
                    // Check for cached nutrition data first
                    let previousData = try await authManager.withAuthRetry { accessToken in
                        try await FoodHistoryService.findPreviousEntry(accessToken: accessToken, foodName: entry.foodName)
                    }

                    var nutrition: APIService.NutritionResponse
                    if let cached = previousData {
                        print("📦 Using cached nutrition for: \(entry.foodName)")
                        nutrition = APIService.NutritionResponse(
                            foodName: entry.foodName,
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
                        print("🌐 Fetching fresh nutrition for: \(entry.foodName)")
                        nutrition = try await authManager.withAuthRetry { accessToken in
                            try await APIService.getNutrition(for: entry.foodName, accessToken: accessToken)
                        }
                    }

                    // Update entry with nutrition data
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

                    // Save to database
                    let dbEntry = try await authManager.withAuthRetry { accessToken in
                        try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[index])
                    }

                    foodEntries[index].dbId = dbEntry.id
                    localNotificationManager.scheduleMealNotification(for: foodEntries[index], userName: userName)

                    print("✅ Auto-calculated: \(entry.foodName)")

                } catch APIError.sessionExpired {
                    // Stop processing if session expires
                    foodEntries[index].isLoading = false
                    break
                } catch APIError.upgradeRequired {
                    // Free tier: save without nutrition (same as offline)
                    foodEntries[index].isLoading = false
                    do {
                        let dbEntry = try await authManager.withAuthRetry { accessToken in
                            try await FoodEntryService.createFoodEntry(accessToken: accessToken, entry: self.foodEntries[index])
                        }
                        foodEntries[index].dbId = dbEntry.id
                        localNotificationManager.scheduleMealNotification(for: foodEntries[index], userName: userName)
                    } catch {
                        print("Failed to save free tier entry during auto-calc: \(error)")
                    }
                    let todayString = Calendar.current.startOfDay(for: Date()).ISO8601Format()
                    if aiLimitAlertShownDate != todayString {
                        aiLimitAlertShownDate = todayString
                        showAiLimitAlert = true
                    }
                    break
                } catch APIError.aiLimitReached {
                    // AI limit reached - stop processing remaining entries
                    foodEntries[index].isLoading = false
                    let todayString = Calendar.current.startOfDay(for: Date()).ISO8601Format()
                    if aiLimitAlertShownDate != todayString {
                        aiLimitAlertShownDate = todayString
                        showAiLimitAlert = true
                    }
                    break
                } catch {
                    // Silent failure for auto-calculation - don't show error banner
                    foodEntries[index].isLoading = false
                    print("Failed to auto-calculate \(entry.foodName): \(error)")
                }
            }

            // Reload weekly data and update calorie progress
            loadWeeklyFoodEntries()
            updateCalorieProgressActivity()

            // Sync achievements after auto-calculation
            if let syncResult = try? await authManager.withAuthRetry({ accessToken in
                try await AchievementService.syncAchievements(accessToken: accessToken)
            }), !syncResult.newlyUnlocked.isEmpty {
                showAwardBanners(syncResult.newlyUnlocked)
            }
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
        Task {
            // Refresh from backend first so the celebration shows the accurate count
            await withTaskGroup(of: Void.self) { _ in refreshStreak() }
            if #available(iOS 16.1, *) {
                guard self.currentStreak > 0 else { return }
                StreakActivityManager.shared.startStreakCelebration(streakDays: self.currentStreak)
            }
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
            goalFats: dailyFatsGoal,
            streakDays: self.currentStreak
        )
    }

}
