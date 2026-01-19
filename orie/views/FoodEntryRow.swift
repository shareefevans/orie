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
    var onDelete: (() -> Void)?

    @State private var showTimePicker = false
    @State private var showNutritionDetail = false
    @State private var selectedTime: Date
    @State private var sparkleScale: CGFloat = 1.0
    @State private var offset: CGFloat = 0
    @State private var showDeleteButton = false

    init(entry: FoodEntry, onTimeChange: @escaping (Date) -> Void, onDelete: (() -> Void)? = nil) {
        self.entry = entry
        self.onTimeChange = onTimeChange
        self.onDelete = onDelete
        _selectedTime = State(initialValue: entry.timestamp)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background
            if showDeleteButton {
                Button(action: {
                    withAnimation {
                        onDelete?()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.callout)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .padding(.trailing, -8)
                .transition(.opacity)
            }

            // Main content
            HStack(alignment: .top, spacing: 0) {
                // Timestamp (left) - Now clickable
                Button(action: {
                    showTimePicker = true
                }) {
                    Text(formatTime(entry.timestamp))
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .frame(width: 90, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Food name - Now clickable
                Button(action: {
                    showNutritionDetail = true
                }) {
                    Text(entry.foodName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
                .disabled(entry.isLoading)

                // Calories (right)
                if entry.isLoading {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 75/255, green: 78/255, blue: 255/255),
                                    Color(red: 106/255, green: 118/255, blue: 255/255)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(sparkleScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                sparkleScale = 1.3
                            }
                        }
                        .frame(width: 90, alignment: .trailing)
                } else if let calories = entry.calories {
                    Text("\(calories) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .trailing)
                }
            }
            .padding(.vertical, 12)
            .background(Color.white)
            .offset(x: offset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                        if isHorizontalDrag && value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                        withAnimation(.easeOut(duration: 0.2)) {
                            if isHorizontalDrag && value.translation.width < -50 {
                                offset = -52
                                showDeleteButton = true
                            } else {
                                offset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
        }
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
        .sheet(isPresented: $showNutritionDetail) {
            NutritionDetailSheet(entry: entry)
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        return formatter.string(from: date).lowercased()
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
