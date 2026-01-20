//
//  ProfileSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct ProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager

    // User data
    @State private var userName = ""
    @State private var dailyCalories = 0
    @State private var dailyProtein = 0
    @State private var dailyCarbs = 0
    @State private var dailyFats = 0
    @State private var isLoading = true
    
    // Personal data
    @State private var age = 0
    @State private var weight = 0
    @State private var height = 0
    @State private var bodyFat = 0
    @State private var gender = ""
    

    // Settings
    @State private var locationEnabled = true
    @State private var notificationsEnabled = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    
                    // Header - Settings and Name centered
                    VStack(alignment: .center, spacing: 2) {
                        Text("Settings")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                Color(
                                    red: 0 / 255,
                                    green: 0 / 255,
                                    blue: 0 / 255
                                )
                            )

                        Text(userName.isEmpty ? "User logged Out" : userName)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    // Feedback and Share buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            // Feedback action
                        }) {
                            Text("Feedback")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .glassEffect(.regular.interactive())

                        Button(action: {
                            // Share action
                        }) {
                            Text("Share")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.yellow)
                                .cornerRadius(100)
                        }
                        .glassEffect(.regular.interactive())
                    }

                    // Body Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Body")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        Color(
                                            red: 0 / 255,
                                            green: 0 / 255,
                                            blue: 0 / 255
                                        )
                                    )
                                
                                Text("Set up your body composition below.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Macro rows
                        MacroRow(label: "Age", value: $age, unit : "yrs", onSave: saveProfile)
                        Divider()
                        MacroRow(label: "Weight", value: $weight, unit: "kg", onSave: saveProfile)
                        Divider()
                        MacroRow(label: "Height", value: $height, unit: "cm", onSave: saveProfile)
                        Divider()
                        MacroRow(label: "Body Fat", value: $bodyFat, unit: "%", onSave: saveProfile)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(24)
                    
                    // Macronutrients Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Macros")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        Color(
                                            red: 0 / 255,
                                            green: 0 / 255,
                                            blue: 0 / 255
                                        )
                                    )
                                
                                Text("Set your daily calorie and macro goals.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Macro rows
                        MacroRow(label: "Calories", value: $dailyCalories, unit: "c", onSave: saveProfile)
                        Divider()
                        MacroRow(label: "Protein", value: $dailyProtein, unit: "g", onSave: saveProfile)
                        Divider()
                        MacroRow(label: "Carbohydrates", value: $dailyCarbs, unit: "g", onSave: saveProfile)
                        Divider()
                        MacroRow(label: "Fats", value: $dailyFats, unit: "g", onSave: saveProfile)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(24)

                    // App Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("App")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        Color(
                                            red: 0 / 255,
                                            green: 0 / 255,
                                            blue: 0 / 255
                                        )
                                    )
                                
                                Text("Manage your app settings.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Settings toggles
                        HStack {
                            Text("Location")
                                .font(.footnote)
                                .fontWeight(.medium)
                            Spacer()
                            Toggle("", isOn: $locationEnabled)
                                .labelsHidden()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Notifications")
                                .font(.footnote)
                                .fontWeight(.medium)
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Colour Mode")
                                .font(.footnote)
                                .fontWeight(.medium)
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                        }
                        
                        Divider()
                        
                        // Log Out
                        Button(action: {
                            Task {
                                await authManager.logout()
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text("Log Out")
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.primary)
                            }
                        }

                        Divider()

                        // Delete Account
                        Button(action: {
                            // Delete account action
                        }) {
                            HStack {
                                Text("Delete Account")
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(24)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color(red: 247/255, green: 247/255, blue: 247/255))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            loadProfile()
        }
    }

    private func loadProfile() {
        guard let accessToken = authManager.getAccessToken() else {
            isLoading = false
            return
        }

        Task {
            do {
                let profile = try await AuthService.getProfile(accessToken: accessToken)
                await MainActor.run {
                    userName = profile.fullName ?? ""
                    age = profile.age ?? 0
                    weight = Int(profile.weight ?? 0)
                    height = Int(profile.height ?? 0)
                    dailyCalories = profile.dailyCalories ?? 0
                    dailyProtein = profile.dailyProtein ?? 0
                    dailyCarbs = profile.dailyCarbs ?? 0
                    dailyFats = profile.dailyFats ?? 0
                    isLoading = false
                }
            } catch {
                print("Failed to load profile: \(error)")
                isLoading = false
            }
        }
    }

    private func saveProfile() {
        guard let accessToken = authManager.getAccessToken() else { return }

        Task {
            do {
                _ = try await AuthService.updateProfile(
                    accessToken: accessToken,
                    age: age > 0 ? age : nil,
                    height: height > 0 ? Double(height) : nil,
                    weight: weight > 0 ? Double(weight) : nil,
                    dailyCalories: dailyCalories > 0 ? dailyCalories : nil,
                    dailyProtein: dailyProtein > 0 ? dailyProtein : nil,
                    dailyCarbs: dailyCarbs > 0 ? dailyCarbs : nil,
                    dailyFats: dailyFats > 0 ? dailyFats : nil
                )
            } catch {
                print("Failed to save profile: \(error)")
            }
        }
    }
}

// Macro Row Component
struct MacroRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    var onSave: (() -> Void)?

    @State private var showPicker = false
    @State private var tempValue: Int

    init(label: String, value: Binding<Int>, unit: String, onSave: (() -> Void)? = nil) {
        self.label = label
        self._value = value
        self.unit = unit
        self.onSave = onSave
        _tempValue = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        Button(action: {
            tempValue = value
            showPicker = true
        }) {
            HStack {
                Text(label)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    if value == 0 {
                        Text("Add \(label)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 2) {
                            Text("\(value)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text(unit)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            MacroPickerSheet(
                label: label,
                value: $tempValue,
                unit: unit,
                onDone: {
                    value = tempValue
                    showPicker = false
                    onSave?()
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
}

// Macro Picker Sheet
struct MacroPickerSheet: View {
    let label: String
    @Binding var value: Int
    let unit: String
    var onDone: () -> Void
    
    @State private var textValue: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    onDone()
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                
                Spacer()
                
                Text("Set \(label)")
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    if let newValue = Int(textValue) {
                        value = newValue
                    }
                    onDone()
                }
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider()
            
            // Text Field Input
            VStack(spacing: 16) {
                TextField("Enter value", text: $textValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .padding()
            }
            .padding(.top, 32)
            
            Spacer()
        }
        .onAppear {
            textValue = "\(value)"
            isTextFieldFocused = true
        }
    }
}

#Preview {
    ProfileSheet()
        .environmentObject(AuthManager())
}
