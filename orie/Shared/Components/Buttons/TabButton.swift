//
//  TabButton.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(isSelected ? .system(size: 16) : .system(size: 14))
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? Color.primaryText(isDark) : Color.secondaryText(isDark))
                    .offset(y: isSelected ? -6 : 0)

                // MARK: 👉 Small dot beneath selected tab
                Circle()
                    .fill(isSelected ? Color.primaryText(isDark) : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TabButton(
        title: "Health",
        isSelected: true,
        isDark: false,
        action: {}
    )
}
