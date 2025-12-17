//
//  ContentView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct MainView: View {
    @State private var foodEntries: [FoodEntry] = []
    @State private var currentInput = ""
    @State private var showAwards = false
    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var showDateSelection = false
    @State private var showMacros = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @FocusState private var isInputFocused: Bool

    // 👉 Mock data for testing
    @State private var totalCalories = 1680
    @State private var totalProtein = 220.0
    @State private var totalCarbs = 195.0
    @State private var totalFats = 50.0
    
    // Computed property to filter entries for selected date
    private var filteredEntries: [FoodEntry] {
        foodEntries.filter { entry in
            Calendar.current.isDate(entry.entryDate, inSameDayAs: selectedDate)
        }
    }
    
    // Check if selected date is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

var body: some View {
        ZStack(alignment: .top) {
            // Main scrollable content
            ScrollViewReader { proxy in
                List {
                    // Top padding spacer
                    Color.clear
                        .frame(height: 60)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    
                    // Date section
                    Text(formattedDate())
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity)
                    
                    // Calories heading
                    HStack {
                        Text("Calories")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                Color(
                                    red: 69 / 255,
                                    green: 69 / 255,
                                    blue: 69 / 255
                                )
                            )
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // Food entries (sorted by time)
                    ForEach(filteredEntries.sorted()) { entry in
                        FoodEntryRow(
                            entry: entry,
                            onTimeChange: { newTime in
                                updateEntryTime(entry.id, newTime: newTime)
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteFoodEntry(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
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
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .id("inputField")
                    
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

            // Floating Bottom Navigation with Heart Button
            VStack {
                Spacer()
                HStack {
                    // Heart button in bottom left
                    Button(action: {
                        showMacros = true
                    }) {
                        Image(systemName: "heart")
                            .font(.callout)
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .glassEffect(.regular.interactive())
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 16)

                    Spacer()
                }
            }
            .background(
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground).opacity(0),
                            Color(.systemBackground),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .sheet(isPresented: $showAwards) {
            AwardSheet()
        }
        .sheet(isPresented: $showProfile) {
            ProfileSheet()
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
    }

    private func addFoodEntry() {
        let newEntry = FoodEntry(foodName: currentInput, entryDate: selectedDate)
        foodEntries.append(newEntry)
        currentInput = ""

        // Call API to get nutrition data
        Task {
            do {
                let nutrition = try await APIService.getNutrition(for: newEntry.foodName)

                // Update the entry with real data
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
                }
            } catch {
                print("Error fetching nutrition: \(error)")
                // Keep loading state or show error
                if let index = foodEntries.firstIndex(where: { $0.id == newEntry.id }) {
                    await MainActor.run {
                        foodEntries[index].isLoading = false
                    }
                }
            }
        }
    }
    
    private func updateEntryTime(_ entryId: UUID, newTime: Date) {
        if let index = foodEntries.firstIndex(where: { $0.id == entryId }) {
            withAnimation {
                foodEntries[index].timestamp = newTime
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy, HH.mm"
        return formatter.string(from: Date())
    }
    
    private func deleteFoodEntry(_ entry: FoodEntry) {
        withAnimation {
            foodEntries.removeAll { $0.id == entry.id }
        }
    }
}

// 👉 Helper view for macro display at bottom (COMMENTED OUT)
//struct MacroDisplay: View {
//    let label: String
//    let value: String
//
//    var body: some View {
//        HStack(spacing: 16) {
//            Text(label)
//                .font(.footnote)
//                .foregroundColor(.secondary)
//
//            Spacer()
//
//            Text(value)
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(.primary)
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 12)
//        .frame(maxWidth: .infinity)
//        .frame(height: 50)
//        .glassEffect(.regular.interactive())
//    }
//}

#Preview {
    MainView()
}
