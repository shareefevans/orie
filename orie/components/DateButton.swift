//
//  DateButton.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let isDark: Bool
    let action: () -> Void

    init(date: Date, isSelected: Bool, isDark: Bool = false, action: @escaping () -> Void) {
        self.date = date
        self.isSelected = isSelected
        self.isDark = isDark
        self.action = action
    }

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    private var daySuffix: String {
        switch dayNumber {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private var dayAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var fullDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var displayText: String {
        if isSelected {
            return "\(fullDayName) \(monthAbbrev) \(dayNumber)"
        } else {
            return "\(dayNumber)\(daySuffix)"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(displayText)
                    .font(isSelected ? .system(size: 16) : .system(size: 14))
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? (isDark ? .white : .black) : Color.tertiaryText(isDark))
                    .offset(y: isSelected ? -6 : 0)

                // Small dot beneath selected date
                Circle()
                    .fill(isSelected ? (isDark ? Color.white : Color.black) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .padding(.top, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DateButton(
        date: Date(),
        isSelected: true,
        isDark: false,
        action: {}
    )
}
