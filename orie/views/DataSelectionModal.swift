//
//  DateSelectionModal.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct DateSelectionModal: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Title - Year and Month on the left
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(yearText())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(
                            Color(
                                red: 69 / 255,
                                green: 69 / 255,
                                blue: 69 / 255
                            )
                        )
                    
                    Text(selectedMonthText())
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            // Horizontal scrolling month tabs
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(generateMonths(), id: \.self) { month in
                            MonthTab(
                                month: month,
                                isSelected: Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month),
                                action: {
                                    withAnimation {
                                        selectedMonth = month
                                    }
                                }
                            )
                            .id(month)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 0)
                }
                .scrollClipDisabled(true)
                .onAppear {
                    // Scroll to selected month
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(selectedMonth, anchor: .center)
                        }
                    }
                }
            }
            .padding(.bottom, 5) // Add space for drop shadow
            
            // Calendar list for selected month
            CalendarGridView(
                month: selectedMonth,
                selectedDate: $selectedDate,
                onDateSelected: {
                    dismiss()
                }
            )
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .background(Color(.systemBackground))
        .onAppear {
            selectedMonth = selectedDate
        }
    }
    
    private func generateMonths() -> [Date] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var months: [Date] = []
        
        // Generate all 12 months of the current year
        for month in 1...12 {
            var components = DateComponents()
            components.year = currentYear
            components.month = month
            components.day = 1
            
            if let date = calendar.date(from: components) {
                months.append(date)
            }
        }
        
        return months
    }
    
    private func yearText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private func selectedMonthText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM, yyy"
        return formatter.string(from: selectedMonth)
    }
}

// Month tab button
struct MonthTab: View {
    let month: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(monthName(month))
                .font(.footnote)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 80, height: 50)
                .background(isSelected ? Color.yellow : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .glassEffect(.regular.interactive())
        }
        .buttonStyle(.plain)
        .frame(width: 80, height: 50)
        .background(isSelected ? Color.yellow : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 100))
        .glassEffect(.regular.interactive())
    }
    
    private func monthName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func year(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

// Calendar list view
struct CalendarGridView: View {
    let month: Date
    @Binding var selectedDate: Date
    var onDateSelected: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    DateRow(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        action: {
                            selectedDate = date
                            onDateSelected()
                        }
                    )
                }
            }
        }
    }
    
    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
}

// Individual date row
struct DateRow: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(formatDate(date))
                    .font(.footnote)
                    .foregroundColor(isSelected ? .white : .primary)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(isSelected ? Color.yellow : Color(.systemGray6))
            )

        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today - 'EEEE, d"
            let suffix = daySuffix(for: date)
            return formatter.string(from: date) + suffix
        } else {
            formatter.dateFormat = "EEEE, d"
            let suffix = daySuffix(for: date)
            return formatter.string(from: date) + suffix
        }
    }
    
    private func daySuffix(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

// Extension to get start of month
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
}

#Preview {
    DateSelectionModal(selectedDate: .constant(Date()))
}
