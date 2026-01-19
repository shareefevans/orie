//
//  FoodInputField.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct FoodInputField: View {
    @Binding var text: String
    var onSubmit: (String) -> Void
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(currentTime())")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .frame(width: 90, alignment: .leading)

            TextField("Tap to Enter Food/s...", text: $text, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(1...5)
                .focused($isFocused)
                .onSubmit {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    text = ""
                    if !trimmed.isEmpty {
                        onSubmit(trimmed)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }
                }
        }
        .padding(.vertical, 12)
    }

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        return formatter.string(from: Date()).lowercased()
    }
}
