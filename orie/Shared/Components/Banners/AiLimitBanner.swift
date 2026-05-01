//
//  AiLimitBanner.swift
//  orie
//

import SwiftUI

struct AiLimitBanner: View {
    let used: Int
    let limit: Int
    var isDark: Bool = false
    var isPremium: Bool = false
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    @State private var dismissTask: Task<Void, Never>? = nil

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.primaryText(isDark))
                .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("You've run out of AI entries today \(used)/\(limit)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                    .fixedSize(horizontal: false, vertical: true)
                if isPremium {
                    Text("Resets tomorrow")
                        .font(.system(size: 12))
                        .foregroundColor(Color.primaryText(isDark).opacity(0.6))
                }
            }

            Spacer(minLength: 0)

            if !isPremium {
                Button(action: onUpgrade) {
                    Text("Upgrade")
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                        .frame(height: 44)
                        .padding(.horizontal, 20)
                        .background(Color.accessibleYellow(isDark).opacity(0.55), in: .capsule)
                }
                .glassEffect(in: .capsule)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.primaryText(isDark))
                    .frame(width: 44, height: 44)
            }
            .glassEffect(in: Circle())
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        #if os(iOS)
        .glassEffect(.regular.tint(isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #else
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #endif
        .environment(\.colorScheme, isDark ? .dark : .light)
        .onAppear {
            dismissTask = Task {
                try? await Task.sleep(for: .seconds(10))
                await MainActor.run { onDismiss() }
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
    }
}

#Preview("AI Limit Banner - Dark") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            AiLimitBanner(used: 3, limit: 3, isDark: true, onUpgrade: {}, onDismiss: {})
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
        }
    }
}

#Preview("AI Limit Banner - Light") {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack {
            Spacer()
            AiLimitBanner(used: 3, limit: 3, isDark: false, onUpgrade: {}, onDismiss: {})
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
        }
    }
}
