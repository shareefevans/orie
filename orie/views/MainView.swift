//
//  ContentView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var foodEntries: [FoodEntry] = []
    @State private var currentInput = ""
    @State private var showAwards = false
    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var showDateSelection = false
    @State private var showMacros = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var selectedTab: String = "consumed"
    @FocusState private var isInputFocused: Bool

    // Animated progress for consumed tab
    @State private var animatedCalorieProgress: Double = 0
    @State private var consumedTabId: UUID = UUID()

    // Daily goals from user profile
    @State private var dailyCalorieGoal: Int = 2300  // Default fallback
    @State private var dailyProteinGoal: Int = 150   // Default fallback
    @State private var dailyCarbsGoal: Int = 250     // Default fallback
    @State private var dailyFatsGoal: Int = 65       // Default fallback

    // Computed property to filter entries for selected date
    private var filteredEntries: [FoodEntry] {
        foodEntries.filter { entry in
            Calendar.current.isDate(entry.entryDate, inSameDayAs: selectedDate)
        }
    }

    // Computed property to calculate total calories from filtered entries
    private var consumedCalories: Int {
        filteredEntries.reduce(0) { total, entry in
            total + (entry.calories ?? 0)
        }
    }

    // Remaining calories
    private var remainingCalories: Int {
        dailyCalorieGoal - consumedCalories
    }

    // Progress percentage (capped at 1.0)
    private var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return min(Double(consumedCalories) / Double(dailyCalorieGoal), 1.0)
    }

    // Consumed protein
    private var consumedProtein: Int {
        Int(filteredEntries.reduce(0.0) { total, entry in
            total + (entry.protein ?? 0)
        })
    }

    // Consumed carbs
    private var consumedCarbs: Int {
        Int(filteredEntries.reduce(0.0) { total, entry in
            total + (entry.carbs ?? 0)
        })
    }

    // Consumed fats
    private var consumedFats: Int {
        Int(filteredEntries.reduce(0.0) { total, entry in
            total + (entry.fats ?? 0)
        })
    }

    // Check if selected date is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

var body: some View {
        ZStack(alignment: .top) {
            // Background color
            Color(red: 247/255, green: 247/255, blue: 247/255)
                .ignoresSafeArea()

            // Main scrollable content
            ScrollViewReader { proxy in
                List {
                    // Top padding spacer
                    Color.clear
                        .frame(height: 68)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    // Tab buttons
                    HStack(spacing: 32) {
                        TabButton(
                            title: "Health",
                            isSelected: selectedTab == "health",
                            action: { selectedTab = "health" }
                        )

                        TabButton(
                            title: "Consumed",
                            isSelected: selectedTab == "consumed",
                            action: { selectedTab = "consumed" }
                        )

                        TabButton(
                            title: "Activity",
                            isSelected: selectedTab == "activity",
                            action: { selectedTab = "activity" }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // Health Tab Content
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
                            dailyFatsGoal: dailyFatsGoal
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    // Consumed Tab Content
                    if selectedTab == "consumed" {
                        VStack(spacing: 8) {
                            // Calorie Tracking Card
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Daily intake")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(consumedCalories.formatted())
                                        .font(.system(size: 24))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)

                                    Text("cal")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                        .fontWeight(.regular)
                                }
                                .padding(.top, 4)

                                Text("\(remainingCalories) remaining")
                                    .font(.system(size: 14))
                                    .foregroundColor(remainingCalories > 0 ? .yellow : .red)
                                    .padding(.top, 4)

                                // Progress bar
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("0")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)

                                        Spacer()

                                        Text(dailyCalorieGoal.formatted())
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                    }

                                    GeometryReader { geometry in
                                        HStack(spacing: 0) {
                                            // Blue progress (expanding)
                                            if animatedCalorieProgress > 0 {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: 75/255, green: 78/255, blue: 255/255),
                                                                Color(red: 106/255, green: 118/255, blue: 255/255)
                                                            ]),
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                    )
                                                    .frame(width: geometry.size.width * min(animatedCalorieProgress, 1.0), height: 6)
                                            }

                                            // Grey bar (contracting)
                                            if animatedCalorieProgress < 1.0 {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: geometry.size.width * (1.0 - min(animatedCalorieProgress, 1.0)), height: 6)
                                            }
                                        }
                                    }
                                    .frame(height: 6)
                                    .id(consumedTabId)
                                    .onAppear {
                                        animatedCalorieProgress = 0

                                        withAnimation(.easeOut(duration: 0.8)) {
                                            animatedCalorieProgress = calorieProgress
                                        }
                                    }
                                    .onChange(of: calorieProgress) { _, newValue in
                                        withAnimation(.easeOut(duration: 0.8)) {
                                            animatedCalorieProgress = newValue
                                        }
                                    }
                                    .onChange(of: selectedTab) { _, newTab in
                                        if newTab == "consumed" {
                                            consumedTabId = UUID()
                                        }
                                    }
                                }
                                .padding(.top, 32)
                            }
                            .padding(.top, 32)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(32)

                            // Food Entries Card
                            VStack(spacing: 0) {
                            // Food entries (sorted by time)
                            ForEach(filteredEntries.sorted()) { entry in
                                FoodEntryRow(
                                    entry: entry,
                                    onTimeChange: { newTime in
                                        updateEntryTime(entry.id, newTime: newTime)
                                    },
                                    onDelete: {
                                        deleteFoodEntry(entry)
                                    }
                                )
                            }

                            // Input field
                            FoodInputField(
                                text: $currentInput,
                                onSubmit: {
                                    addFoodEntry()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            proxy.scrollTo("inputField", anchor: .top)
                                        }
                                    }
                                },
                                isFocused: $isInputFocused
                            )
                            .id("inputField")
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                            .frame(minHeight: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(32)
                        }
                        .padding(.horizontal, 16)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    // Bottom padding
                    Color.clear
                        .frame(height: 120)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: foodEntries.count) { oldValue, newValue in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("inputField", anchor: .top)
                        }
                    }
                }
            }

            // 🔝 Floating Top Navigation Bar
            VStack(spacing: 0) {
                TopNavigationBar(
                    showAwards: $showAwards,
                    showProfile: $showProfile,
                    showDateSelection: $showDateSelection,
                    showNotifications: $showNotifications,
                    selectedDate: selectedDate,
                    isToday: isToday,
                    isInputFocused: Binding(
                        get: { isInputFocused },
                        set: { isInputFocused = $0 }
                    )
                )
                Spacer()
            }
            .background(
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            )


            // Bottom fade overlay
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 247/255, green: 247/255, blue: 247/255).opacity(0),
                        Color(red: 247/255, green: 247/255, blue: 247/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showAwards) {
            AwardSheet()
        }
        .sheet(isPresented: $showProfile, onDismiss: {
            loadUserProfile()  // Reload in case user updated their calorie goal
        }) {
            ProfileSheet()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationSheet()
        }
        .sheet(isPresented: $showDateSelection) {
            DateSelectionModal(selectedDate: $selectedDate)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMacros) {
            MacrosSheet()
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
                .presentationBackground(.bar)
        }
        .onAppear {
            loadFoodEntries()
            loadUserProfile()
        }
        .onChange(of: selectedDate) { _, _ in
            loadFoodEntries()
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                loadFoodEntries()
                loadUserProfile()
            } else {
                // Clear entries when user logs out
                foodEntries = []
                dailyCalorieGoal = 2300  // Reset to default
                dailyProteinGoal = 150   // Reset to default
                dailyCarbsGoal = 250     // Reset to default
                dailyFatsGoal = 65       // Reset to default
            }
        }
    }

    private func addFoodEntry() {
        guard let accessToken = authManager.getAccessToken() else { return }

        let newEntry = FoodEntry(foodName: currentInput, entryDate: selectedDate)
        foodEntries.append(newEntry)
        currentInput = ""

        Task {
            do {
                // Get nutrition data
                let nutrition = try await APIService.getNutrition(for: newEntry.foodName)

                // Update local entry
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

                    // Save to database
                    let dbEntry = try await FoodEntryService.createFoodEntry(
                        accessToken: accessToken,
                        entry: foodEntries[index]
                    )

                    // Update with database ID
                    await MainActor.run {
                        foodEntries[index].dbId = dbEntry.id
                    }
                }
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
    
    private func updateEntryTime(_ entryId: UUID, newTime: Date) {
        guard let accessToken = authManager.getAccessToken(),
              let index = foodEntries.firstIndex(where: { $0.id == entryId }),
              let dbId = foodEntries[index].dbId else { return }

        withAnimation {
            foodEntries[index].timestamp = newTime
        }

        Task {
            do {
                _ = try await FoodEntryService.updateFoodEntry(
                    accessToken: accessToken,
                    id: dbId,
                    timestamp: newTime
                )
            } catch {
                print("Failed to update entry time: \(error)")
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy, HH.mm"
        return formatter.string(from: Date())
    }
    
    private func deleteFoodEntry(_ entry: FoodEntry) {
        guard let accessToken = authManager.getAccessToken() else { return }

        withAnimation {
            foodEntries.removeAll { $0.id == entry.id }
        }

        if let dbId = entry.dbId {
            Task {
                do {
                    try await FoodEntryService.deleteFoodEntry(
                        accessToken: accessToken,
                        id: dbId
                    )
                } catch {
                    print("Failed to delete entry: \(error)")
                }
            }
        }
    }

    // MARK: - Profile Management

    private func loadUserProfile() {
        guard let accessToken = authManager.getAccessToken() else { return }

        Task {
            do {
                let profile = try await AuthService.getProfile(accessToken: accessToken)
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
            } catch {
                print("Failed to load user profile: \(error)")
            }
        }
    }

    // MARK: - Food Entry Management

    private func loadFoodEntries() {
        guard let accessToken = authManager.getAccessToken() else { return }

        Task {
            do {
                let entries = try await FoodEntryService.getFoodEntries(
                    accessToken: accessToken,
                    date: selectedDate
                )

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

                        // Parse timestamp
                        if let timestamp = ISO8601DateFormatter().date(from: dbEntry.timestamp) {
                            entry.timestamp = timestamp
                        }

                        return entry
                    }
                }
            } catch {
                print("Failed to load food entries: \(error)")
            }
        }
    }
}

// Tab Button Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(isSelected ? .system(size: 16) : .system(size: 14))
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .black : .gray)
                    .offset(y: isSelected ? -6 : 0)

                // Small black dot beneath selected tab
                Circle()
                    .fill(isSelected ? Color.black : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainView()
        .environmentObject(AuthManager())
}
