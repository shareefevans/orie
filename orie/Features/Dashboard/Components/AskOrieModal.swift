//
//  AskOrieModal.swift
//  orie
//

import SwiftUI

struct AskOrieModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

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

    private var isDark: Bool { themeManager.isDarkMode }

    private let suggestions: [(icon: String, text: String)] = [
        ("magnifyingglass", "How many calories in 100g of rice?"),
        ("doc.plaintext", "Create a high protein recipe for dinner?"),
        ("sparkles", "What should i eat for lunch?")
    ]

    private var showingIntro: Bool { messages.isEmpty }

    // MARK: - Body

    private var topControls: some View {
        HStack {
            Button(action: { clearChat() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                    .frame(width: 44, height: 44)
            }
            #if os(iOS)
            .glassEffect(in: Circle())
            #endif
            Spacer()
            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "circle.hexagonpath.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Orie")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color.primaryText(isDark))
                .padding(.horizontal, 14)
                .frame(height: 44)
            }
            #if os(iOS)
            .glassEffect(in: Capsule())
            #endif
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                    .frame(width: 44, height: 44)
            }
            #if os(iOS)
            .glassEffect(in: Circle())
            #endif
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    var body: some View {
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
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 76) }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 100) }
            .onAppear { scrollProxy = proxy }
        }
        .overlay(alignment: .top) { topControls }
        .overlay(alignment: .bottom) { inputBar }
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
                    .fill(Color.primaryText(isDark))
                    .frame(width: 64, height: 64)
                Image(systemName: "circle.hexagonpath.fill")
                    .font(.system(size: 26))
                    .foregroundColor(isDark ? .black : .white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text("How can I help you today?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.primaryText(isDark))
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
                                .foregroundColor(Color.secondaryText(isDark))
                                .frame(width: 20)
                            Text(suggestion.text)
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondaryText(isDark))
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
                                 text: "\(remainingCalories)cal Remaining", isDark: isDark)
                    OrieStatPill(color: Color(red: 49/255, green: 209/255, blue: 149/255),
                                 text: "\(consumedProtein)g Protein", isDark: isDark)
                    OrieStatPill(color: Color(red: 135/255, green: 206/255, blue: 250/255),
                                 text: "\(consumedCarbs)g Carbs", isDark: isDark)
                    OrieStatPill(color: Color(red: 255/255, green: 204/255, blue: 51/255),
                                 text: "\(consumedFats)g Fat", isDark: isDark)
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
                ChatBubble(message: message, isLast: message.id == messages.last?.id, isDark: isDark)
                    .id(message.id)
            }
            if isLoading {
                TypingIndicator(isDark: isDark)
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
        HStack(alignment: .bottom, spacing: 0) {
            TextField("Ask anything food related...", text: $messageText, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(Color.primaryText(isDark))
                .tint(Color.primaryText(isDark))
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
                            ? Color.primaryText(isDark).opacity(0.25)
                            : Color(red: 0.25, green: 0.45, blue: 1.0),
                        in: Circle()
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .padding(.trailing, isTextFieldFocused ? 8 : 8)
            .padding(.bottom, isTextFieldFocused ? 8 : 7)
        }
        .overlay(alignment: .bottomLeading) {
            if isTextFieldFocused {
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.secondaryText(isDark))
                    }
                    Button(action: {}) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.secondaryText(isDark))
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

    private func isFoodRelated(_ text: String) -> Bool {
        let lower = text.lowercased()
        let keywords = [
            "calorie", "calori", "kcal", "kj", "kilojoule",
            "protein", "carb", "carbohydrate", "fat", "fibre", "fiber", "sugar", "sodium", "macro",
            "food", "eat", "eating", "meal", "breakfast", "lunch", "dinner", "snack", "diet",
            "recipe", "ingredient", "cook", "portion", "serving", "nutrition", "nutrient",
            "weight", "lose weight", "gain weight", "bulk", "cut", "deficit", "surplus",
            "vegetable", "fruit", "meat", "chicken", "beef", "fish", "seafood", "dairy", "egg",
            "bread", "rice", "pasta", "grain", "legume", "bean", "nut", "seed", "oil", "sauce",
            "drink", "juice", "smoothie", "shake", "supplement", "vitamin", "mineral",
            "hunger", "hungry", "full", "satiat", "appetite", "bmi", "body mass",
            "health", "healthy", "workout", "gym", "exercise", "training", "muscle",
            "log", "track", "today", "yesterday", "remaining", "goal", "target",
            "how many", "how much", "what should", "what can", "suggest", "recommend"
        ]
        return keywords.contains { lower.contains($0) }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        messageText = ""
        isLoading = true
        scrollToBottom()

        guard isFoodRelated(text) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isLoading = false
                messages.append(ChatMessage(role: .assistant, content: "I can only help with food, nutrition, and calorie-related questions. Try asking me about a meal, your macros, or what to eat today."))
                trimHistory()
                saveHistory()
                scrollToBottom()
            }
            return
        }

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
    var isLast: Bool = false
    var isDark: Bool = true

    var body: some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 60)
                Text(message.content)
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(4)
                    .foregroundColor(Color.primaryText(isDark))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(message.content)
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(6)
                    .foregroundColor(Color.primaryText(isDark).opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "hand.thumbsup")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark).opacity(0.35))
                    }
                    .buttonStyle(.plain)

                    Button(action: {}) {
                        Image(systemName: "hand.thumbsdown")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark).opacity(0.35))
                    }
                    .buttonStyle(.plain)

                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark).opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)

                if isLast {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.hexagonpath.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primaryText(isDark))
                        Text("Orie is AI and can make mistakes.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText(isDark))
                        Spacer()
                    }
                    .padding(.top, 14)
                }
            }
        }
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    var isDark: Bool = true
    @State private var displayedText = ""
    @State private var phaseIndex = 0
    @State private var charIndex = 0
    @State private var sparkleScale: CGFloat = 1.0
    @State private var sparkleOpacity: Double = 1.0

    private let phases = ["Thinking", "Generating", "Almost there"]
    private let typingSpeed: Double = 0.055
    private let pauseDuration: Double = 0.75

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.primaryText(isDark).opacity(0.85))
                .scaleEffect(sparkleScale)
                .opacity(sparkleOpacity)
            Text(displayedText)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.secondaryText(isDark))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                sparkleScale = 1.35
                sparkleOpacity = 0.45
            }
            typeNextChar()
        }
    }

    private func typeNextChar() {
        let phrase = phases[phaseIndex]
        if charIndex < phrase.count {
            let idx = phrase.index(phrase.startIndex, offsetBy: charIndex)
            displayedText += String(phrase[idx])
            charIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) {
                typeNextChar()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) {
                displayedText = ""
                charIndex = 0
                phaseIndex = (phaseIndex + 1) % phases.count
                typeNextChar()
            }
        }
    }
}

// MARK: - Stat Pill

private struct OrieStatPill: View {
    var color: Color
    var text: String
    var isDark: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.primaryText(isDark).opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), in: Capsule())
        .overlay(Capsule().stroke(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.1), lineWidth: 1))
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
