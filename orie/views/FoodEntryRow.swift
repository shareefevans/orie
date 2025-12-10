//
//  FoodEntryRow.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry
    var onTimeChange: (Date) -> Void

    @State private var showTimePicker = false
    @State private var selectedTime: Date
    @State private var sparkleScale: CGFloat = 1.0
    
    init(entry: FoodEntry, onTimeChange: @escaping (Date) -> Void) {
        self.entry = entry
        self.onTimeChange = onTimeChange
        _selectedTime = State(initialValue: entry.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp (left) - Now clickable
            Button(action: {
                showTimePicker = true
            }) {
                Text(formatTime(entry.timestamp))
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                    .frame(width: 90, alignment: .leading)
            }
            .buttonStyle(.plain)
            
            // Food name
            Text(entry.foodName)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Calories (right)
            if entry.isLoading {
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .scaleEffect(sparkleScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            sparkleScale = 1.3
                        }
                    }
                    .frame(width: 90, alignment: .trailing)
            } else if let calories = entry.calories {
                Text("\(calories) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .trailing)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                selectedTime: $selectedTime,
                onDone: {
                    onTimeChange(selectedTime)
                    showTimePicker = false
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        return "\(formatter.string(from: date))"
    }
}

// Time Picker Sheet
struct TimePickerSheet: View {
    @Binding var selectedTime: Date
    var onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Set Time") {
                    onDone()
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                
                Spacer()
            
                
                Button("Done") {
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
            
            // Time Picker
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            
            Spacer()
        }
    }
}
