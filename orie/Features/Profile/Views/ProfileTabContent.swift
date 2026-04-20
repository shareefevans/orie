//
//  ProfileTabContent.swift
//  orie
//

import SwiftUI

struct ProfileTabContent: View {
    let isLoading: Bool
    let isDark: Bool
    @Binding var age: Int
    @Binding var weight: Int
    @Binding var height: Int
    @Binding var bodyFat: Int
    @Binding var dailyCalories: Int
    @Binding var dailyProtein: Int
    @Binding var dailyCarbs: Int
    @Binding var dailyFats: Int
    @Binding var dailySodium: Int
    @Binding var dailyFibre: Int
    @Binding var dailySugar: Int
    var onSave: () -> Void

    @AppStorage("isMetricSystem") private var isMetric = true
    @State private var showSystemPicker = false

    var body: some View {
        if isLoading {
            ProfileSheetSkeleton(isDark: isDark, tab: .profile)
        } else {
            bodyCard
            macrosCard
        }
    }

    // MARK: - Body Card
    private var bodyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Personal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))
                Text("Enter your details.")
                    .font(.footnote)
                    .foregroundColor(Color.secondaryText(isDark))
                    .padding(.bottom, 4)
            }
            .padding(.bottom, 16)

            setupDivider
            SetupPickerRow(label: "System", value: isMetric ? "Metric" : "Imperial", isDark: isDark, icon: "globe") {
                showSystemPicker = true
            }
            setupDivider
            MacroRow(icon: "calendar", label: "Age", value: $age, unit: "yrs", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(icon: "scalemass", label: "Weight", value: $weight, unit: isMetric ? "kg" : "lbs", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(icon: "ruler", label: "Height", value: $height, unit: isMetric ? "cm" : "in", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(icon: "drop.degreesign", label: "Body Fat", value: $bodyFat, unit: "%", isDark: isDark, onSave: onSave)
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
        .sheet(isPresented: $showSystemPicker) {
            WheelPickerSheet(
                options: ["Metric", "Imperial"],
                selection: Binding(
                    get: { isMetric ? "Metric" : "Imperial" },
                    set: { isMetric = $0 == "Metric" }
                )
            ) { showSystemPicker = false }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.cardBackground(isDark))
        }
    }

    // MARK: - Macros Card
    private var macrosCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nutrition")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))
                Text("Set your daily calorie and macro goals.")
                    .font(.footnote)
                    .foregroundColor(Color.secondaryText(isDark))
                    .padding(.bottom, 4)
            }
            .padding(.bottom, 16)

            setupDivider
            MacroRow(dotColor: Color(red: 106/255, green: 118/255, blue: 255/255), label: "Calories", value: $dailyCalories, unit: "kcal", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(dotColor: Color(red: 49/255, green: 209/255, blue: 149/255), label: "Protein", value: $dailyProtein, unit: "g", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(dotColor: Color(red: 135/255, green: 206/255, blue: 250/255), label: "Carbohydrates", value: $dailyCarbs, unit: "g", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(dotColor: Color(red: 255/255, green: 180/255, blue: 50/255), label: "Fats", value: $dailyFats, unit: "g", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(dotColor: Color(red: 255/255, green: 105/255, blue: 180/255), label: "Sodium", value: $dailySodium, unit: "mg", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(dotColor: Color(red: 160/255, green: 80/255, blue: 255/255), label: "Fibre", value: $dailyFibre, unit: "g", isDark: isDark, onSave: onSave)
            setupDivider
            MacroRow(dotColor: Color(red: 255/255, green: 30/255, blue: 60/255), label: "Sugar", value: $dailySugar, unit: "g", isDark: isDark, onSave: onSave)
        }
        .padding(24)
        .background(Color.cardBackground(isDark))
        .cornerRadius(32)
    }

    // MARK: - Shared
    private var setupDivider: some View {
        Rectangle()
            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
            .frame(height: 1)
    }

}

#Preview {
    ProfileTabContent(
        isLoading: false,
        isDark: true,
        age: .constant(28),
        weight: .constant(80),
        height: .constant(180),
        bodyFat: .constant(15),
        dailyCalories: .constant(2200),
        dailyProtein: .constant(160),
        dailyCarbs: .constant(250),
        dailyFats: .constant(70),
        dailySodium: .constant(2000),
        dailyFibre: .constant(30),
        dailySugar: .constant(50),
        onSave: {}
    )
    .padding()
    .background(Color.black)
}
