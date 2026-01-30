//
//  ThemeManager.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false

    private let themeKey = "isDarkMode"
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load saved preference, default to dark mode if not set
        if UserDefaults.standard.object(forKey: themeKey) == nil {
            isDarkMode = true // Default to dark mode for new users
        } else {
            isDarkMode = UserDefaults.standard.bool(forKey: themeKey)
        }

        // Save whenever isDarkMode changes
        $isDarkMode
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                UserDefaults.standard.set(newValue, forKey: self.themeKey)
            }
            .store(in: &cancellables)
    }

    func toggle() {
        isDarkMode.toggle()
    }
}

// MARK: - Theme Colors
extension Color {
    // Background colors
    static func appBackground(_ isDark: Bool) -> Color {
        isDark ? Color(red: 24/255, green: 24/255, blue: 24/255) : Color(red: 247/255, green: 247/255, blue: 247/255)
    }

    static func cardBackground(_ isDark: Bool) -> Color {
        isDark ? Color(red: 30/255, green: 30/255, blue: 30/255) : Color.white
    }

    // Chart/graph background (grey parts)
    static func chartBackground(_ isDark: Bool) -> Color {
        isDark ? Color(red: 54/255, green: 54/255, blue: 54/255) : Color(red: 230/255, green: 230/255, blue: 230/255)
    }

    // Text colors
    static func primaryText(_ isDark: Bool) -> Color {
        isDark ? Color.white : Color.black
    }

    static func secondaryText(_ isDark: Bool) -> Color {
        isDark ? Color(white: 0.7) : Color.secondary
    }

    // Tertiary text (lighter grey for non-selected items in dark mode)
    static func tertiaryText(_ isDark: Bool) -> Color {
        isDark ? Color(white: 0.5) : Color.gray
    }

    // Icon colors
    static func iconColor(_ isDark: Bool) -> Color {
        isDark ? Color.white : Color.black
    }

    // Placeholder text color
    static func placeholderText(_ isDark: Bool) -> Color {
        isDark ? Color(white: 0.5) : Color.gray
    }

    // Accent blue for Done buttons (consistent across light/dark mode)
    static var accentBlue: Color {
        Color(red: 0/255, green: 122/255, blue: 255/255)
    }

    // Accessible yellow (golden in light mode for readability)
    static func accessibleYellow(_ isDark: Bool) -> Color {
        isDark ? Color.yellow : Color(red: 253/255, green: 181/255, blue: 0/255)
    }
}
