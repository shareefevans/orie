//
//  AskOrieModal.swift
//  orie
//

import SwiftUI

struct AskOrieModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager

    var remainingCalories: Int
    var consumedCalories: Int
    var consumedProtein: Int
    var consumedCarbs: Int
    var consumedFats: Int
    var calorieGoal: Int
    var proteinGoal: Int
    var carbsGoal: Int
    var foodEntries: [FoodEntry]

    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var isLoading = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let historyKey = "orie_chat_history"
    private let maxHistory = 20

    private let suggestions: [(icon: String, text: String)] = [
        ("magnifyingglass", "How many calories in 100g of rice?"),
        ("doc.plaintext", "Create a high protein recipe for dinner?"),
        ("sparkles", "What should i eat for lunch?")
    ]

    private var showingIntro: Bool { messages.isEmpty }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Fixed Top Controls
            HStack {
                Button(action: { clearChat() }) {
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
            .padding(.bottom, 12)

            // MARK: - Content
            ScrollViewReader { proxy in
                ScrollView {
                    if showingIntro {
                        introContent
                    } else {
                        chatContent
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { isTextFieldFocused = false }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 4) }
                .onAppear { scrollProxy = proxy }
            }

            // MARK: - Input Bar
            inputBar
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            loadHistory()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Intro

    private var introContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                Image(systemName: "circle.hexagonpath.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text("How can I help you today?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 16)

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
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    OrieStatPill(color: Color(red: 106/255, green: 118/255, blue: 255/255),
                                 text: "\(remainingCalories)cal Remaining")
                    OrieStatPill(color: Color(red: 49/255, green: 209/255, blue: 149/255),
                                 text: "\(consumedProtein)g Protein")
                    OrieStatPill(color: Color(red: 135/255, green: 206/255, blue: 250/255),
                                 text: "\(consumedCarbs)g Carbs")
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chat

    private var chatContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(messages) { message in
                ChatBubble(message: message)
                    .id(message.id)
            }
            if isLoading {
                TypingIndicator()
                    .id("typing")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .center, spacing: 0) {
            TextField("Ask anything food related...", text: $messageText, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .tint(.white)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, isTextFieldFocused ? 14 : 13)
                .padding(.bottom, isTextFieldFocused ? 36 : 0)

            Button(action: { sendMessage() }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                            ? Color.white.opacity(0.25)
                            : Color(red: 0.25, green: 0.45, blue: 1.0),
                        in: Circle()
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .padding(.trailing, 12)
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

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        messageText = ""
        isLoading = true
        scrollToBottom()

        Task {
            do {
                let payload = messages.map {
                    APIService.ChatMessagePayload(role: $0.role.rawValue, content: $0.content)
                }

                let context = APIService.ChatContext(
                    remainingCalories: remainingCalories,
                    consumedCalories: consumedCalories,
                    consumedProtein: consumedProtein,
                    consumedCarbs: consumedCarbs,
                    consumedFats: consumedFats,
                    calorieGoal: calorieGoal,
                    proteinGoal: proteinGoal,
                    carbsGoal: carbsGoal,
                    foodEntries: foodEntries.compactMap { entry in
                        guard !entry.isLoading, let cal = entry.calories else { return nil }
                        return "\(entry.foodName) (\(cal) cal)"
                    }
                )

                let response = try await authManager.withAuthRetry { token in
                    try await APIService.chat(messages: payload, context: context, accessToken: token)
                }

                await MainActor.run {
                    isLoading = false
                    messages.append(ChatMessage(role: .assistant, content: response.message))
                    trimHistory()
                    saveHistory()
                    scrollToBottom()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorText: String
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .aiLimitReached: errorText = "You've reached your daily AI limit. Upgrade to continue."
                        case .upgradeRequired: errorText = "This feature requires a premium subscription."
                        default: errorText = "Something went wrong. Please try again."
                        }
                    } else {
                        errorText = "Something went wrong. Please try again."
                    }
                    messages.append(ChatMessage(role: .assistant, content: errorText))
                    scrollToBottom()
                }
            }
        }
    }

    private func scrollToBottom() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                if isLoading {
                    scrollProxy?.scrollTo("typing", anchor: .bottom)
                } else if let last = messages.last {
                    scrollProxy?.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func clearChat() {
        messages = []
        messageText = ""
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func trimHistory() {
        if messages.count > maxHistory {
            messages = Array(messages.suffix(maxHistory))
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = saved
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 60)
                Text(message.content)
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(4)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        } else {
            Text(message.content)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(6)
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
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
    AskOrieModal(
        remainingCalories: 400,
        consumedCalories: 1600,
        consumedProtein: 184,
        consumedCarbs: 199,
        consumedFats: 55,
        calorieGoal: 2000,
        proteinGoal: 180,
        carbsGoal: 200,
        foodEntries: []
    )
    .preferredColorScheme(.dark)
}
