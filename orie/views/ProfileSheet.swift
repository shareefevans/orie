//
//  ProfileSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct ProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    
    // Mock user data
    @State private var userName = "Shareef Evans"
    @State private var dailyCalories = 0
    @State private var dailyProtein = 0
    @State private var dailyCarbs = 0
    @State private var dailyFats = 0
    
    // Settings
    @State private var locationEnabled = true
    @State private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Settings and Name on the left
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Settings")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(
                                    Color(
                                        red: 69 / 255,
                                        green: 69 / 255,
                                        blue: 69 / 255
                                    )
                                )
                            
                            Text(userName)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                    
                    // Macronutrients Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Emoji/Icon placeholder
                            Image("AwardPurpleOne")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Macronutrients")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        Color(
                                            red: 69 / 255,
                                            green: 69 / 255,
                                            blue: 69 / 255
                                        )
                                    )
                                
                                Text("Set your daily calorie and macro goals to track your nutrition targets.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Macro rows
                        MacroRow(label: "Calories", value: $dailyCalories, unit: "c")
                        Divider()
                        MacroRow(label: "Protein", value: $dailyProtein, unit: "g")
                        Divider()
                        MacroRow(label: "Carbohydrates", value: $dailyCarbs, unit: "g")
                        Divider()
                        MacroRow(label: "Fats", value: $dailyFats, unit: "g")
                    }
                    .padding(24)
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                    
                    // App Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            // App icon placeholder
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        Color(
                                            red: 69 / 255,
                                            green: 69 / 255,
                                            blue: 69 / 255
                                        )
                                    )
                                
                                Text("Manage your app preferences, permissions, and account settings.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.bottom, 8)
                        
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
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
    }
}

// Macro Row Component
struct MacroRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    
    @State private var showPicker = false
    @State private var tempValue: Int
    
    init(label: String, value: Binding<Int>, unit: String) {
        self.label = label
        self._value = value
        self.unit = unit
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
}
