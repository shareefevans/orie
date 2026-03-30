//
//  AskOrieModal.swift
//  orie
//
//  Created by Shareef Evans on 30/03/2026.
//

import SwiftUI

struct AskOrieModal: View {
    @Environment(\.dismiss) private var dismiss

    var remainingCalories: Int
    var consumedProtein: Int
    var consumedCarbs: Int

    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    private let suggestions: [(icon: String, text: String)] = [
        ("magnifyingglass", "How many calories in 100g of rice?"),
        ("doc.plaintext", "Create a high protein recipe for dinner?"),
        ("sparkles", "What should i eat for lunch?")
    ]

    var body: some View {
        ZStack {
            Color(red: 18/255, green: 18/255, blue: 18/255)
                .ignoresSafeArea()
                .onTapGesture { isTextFieldFocused = false }

            VStack(alignment: .leading, spacing: 0) {

                // MARK: - Top Controls
                HStack {
                    Button(action: { messageText = "" }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(.regular.interactive())
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(.regular.interactive())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // MARK: - Avatar
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                    Image(systemName: "circle.hexagonpath.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                // MARK: - Title
                Text("How can I help you today?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // MARK: - Suggestions
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(suggestions, id: \.text) { suggestion in
                        Button(action: {
                            messageText = suggestion.text
                            isTextFieldFocused = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: suggestion.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.55))
                                    .frame(width: 20)
                                Text(suggestion.text)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                // MARK: - Stats Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        OrieStatPill(color: Color(red: 0.35, green: 0.55, blue: 1.0),
                                     text: "\(remainingCalories)cal Remaining")
                        OrieStatPill(color: Color(red: 0.2, green: 0.85, blue: 0.55),
                                     text: "\(consumedProtein)g Protein")
                        OrieStatPill(color: Color(red: 0.65, green: 0.4, blue: 1.0),
                                     text: "\(consumedCarbs)g Carbohy...")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 28)

                Spacer()

                // MARK: - Input Area
                HStack(alignment: .center, spacing: 0) {
                    TextField("Ask anything food related...", text: $messageText, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .tint(.white)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, isTextFieldFocused ? 14 : 13)
                        .padding(.bottom, isTextFieldFocused ? 36 : 0)
                        .onTapGesture { isTextFieldFocused = true }

                    Button(action: { /* send action placeholder */ }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                isTextFieldFocused
                                    ? Color(red: 0.25, green: 0.45, blue: 1.0)
                                    : Color.white.opacity(0.25),
                                in: Circle()
                            )
                    }
                    .padding(.trailing, 12)
                    .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                }
                .overlay(alignment: .bottomLeading) {
                    if isTextFieldFocused {
                        HStack(spacing: 16) {
                            Button(action: {}) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Button(action: {}) {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 10)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isTextFieldFocused)
                #if os(iOS)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                #else
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                #endif
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Stat Pill

private struct OrieStatPill: View {
    var color: Color
    var text: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

#Preview {
    AskOrieModal(remainingCalories: 400, consumedProtein: 184, consumedCarbs: 199)
        .preferredColorScheme(.dark)
}
