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
    @FocusState private var isInputFocused: Bool

    // 👉 Mock data for testing
    @State private var totalCalories = 1680
    @State private var totalProtein = 220.0
    @State private var totalCarbs = 195.0
    @State private var totalFats = 50.0

    var body: some View {
        ZStack(alignment: .top) {
            // Main scrollable content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Top padding to push content below fixed nav bar
                        Spacer()
                            .frame(height: 60)  // Height of TopNavigationBar

                        // ⏰ Date and Time (SCROLLS)
                        Text(formattedDate())
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        // 🍩 "Calories" Heading (SCROLLS)
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

                        // Food entries
                        ForEach(foodEntries) { entry in
                            FoodEntryRow(entry: entry)
                                .id(entry.id)
                        }

                        // Input field for new entry
                        FoodInputField(
                            text: $currentInput,
                            onSubmit: {
                                addFoodEntry()

                                // Scroll to input field after adding
                                DispatchQueue.main.asyncAfter(
                                    deadline: .now() + 0.1
                                ) {
                                    withAnimation {
                                        proxy.scrollTo(
                                            "inputField",
                                            anchor: .top
                                        )
                                    }
                                }
                            },
                            isFocused: $isInputFocused  // ← Move to end
                        )
                        .id("inputField")

                        // Extra padding at bottom - to clear macro display
                        Spacer()
                            .frame(height: 120)
                    }
                }
                .onChange(of: foodEntries.count) { oldValue, newValue in
                    // Auto-scroll when new entry is added
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
                    showProfile: $showProfile
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

            // 🍑 Floating Bottom Macro Tracker
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    MacroDisplay(
                        label: "Remaining",
                        value: "\(totalCalories) cal"
                    )

                    // Done button (only shows when keyboard is open)
                    if isInputFocused {
                        Button(action: {
                            isInputFocused = false  // Close keyboard
                        }) {
                            Image(systemName: "checkmark")
                                .font(.callout)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.yellow)
                                .clipShape(Circle())
                                .glassEffect(.regular.interactive())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
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
            Text("Awards Sheet - Coming Soon")
        }
        .sheet(isPresented: $showProfile) {
            Text("Profile Sheet - Coming Soon")
        }
    }

    private func addFoodEntry() {
        let newEntry = FoodEntry(foodName: currentInput)
        foodEntries.append(newEntry)
        currentInput = ""

        // 👉 TODO: Call API here to get calories
        // 👉 For now, simulate with mock data after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let index = foodEntries.firstIndex(where: {
                $0.id == newEntry.id
            }) {
                foodEntries[index].calories = Int.random(in: 100...600)
                foodEntries[index].isLoading = false
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy, HH.mm"
        return formatter.string(from: Date())
    }
}

// 👉 Helper view for macro display at bottom
struct MacroDisplay: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .glassEffect(.regular.interactive())
    }
}

#Preview {
    MainView()
}
