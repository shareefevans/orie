//
//  FoodEntryRow.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp (left)
            Text(formatTime(entry.timestamp))
                .font(.subheadline)
                .foregroundColor(.yellow)
                .frame(width: 90, alignment: .leading)
            
            // Food name
            Text(entry.foodName)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Calories (right)
            if entry.isLoading {
                ProgressView()
                    .frame(width: 90)
            } else if let calories = entry.calories {
                Text("\(calories) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .trailing)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH.mm"
        return "@\(formatter.string(from: date))"
    }
}

