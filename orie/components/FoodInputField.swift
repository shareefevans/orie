//
//  FoodInputField.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct FoodInputField: View {
    @Binding var text: String
    var onSubmit: (String) -> Void  // Now passes the text value directly
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\(currentTime())")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .frame(width: 90, alignment: .leading)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Tap to Enter Food/s...")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.system(size: 15))
                        .padding(.leading, 5)
                }

                TextEditor(text: $text)
                    .font(.system(size: 15))
                    .frame(minHeight: 20)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .offset(y: -8)
                    .focused($isFocused)
                    .onChange(of: text) { oldValue, newValue in
                        if newValue.contains("\n") {
                            let strippedText = newValue.replacingOccurrences(of: "\n", with: "")
                            text = ""  // Clear immediately
                            if !strippedText.isEmpty {
                                onSubmit(strippedText)  // Pass the value directly
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isFocused = true
                                }
                            }
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
