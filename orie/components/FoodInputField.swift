//
//  FoodInputField.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct FoodInputField: View {
    @Binding var text: String
    var onSubmit: () -> Void
    @FocusState.Binding var isFocused: Bool  // ← Changed to accept binding
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(currentTime())")
                .font(.subheadline)
                .foregroundColor(.yellow)
                .frame(width: 90, alignment: .leading)
                .padding(.top, 8)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Tap to Enter Food/s...")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.subheadline)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $text)
                    .font(.subheadline)
                    .frame(minHeight: 20)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .onChange(of: text) { oldValue, newValue in
                        if newValue.contains("\n") {
                            text = newValue.replacingOccurrences(of: "\n", with: "")
                            if !text.isEmpty {
                                onSubmit()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isFocused = true
                                }
                            }
                        }
                    }
                    .onAppear {
                        isFocused = true
                    }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mma"
        return formatter.string(from: Date())
    }
}
