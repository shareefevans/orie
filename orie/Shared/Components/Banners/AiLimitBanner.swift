//
//  AiLimitBanner.swift
//  orie
//

import SwiftUI

struct AiLimitBanner: View {
    let used: Int
    let limit: Int
    var isDark: Bool = false
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.primaryText(isDark))

            Text("You've run out of AI entries today \(used)/\(limit)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.primaryText(isDark))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

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
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        #if os(iOS)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #else
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #endif
    }
}

#Preview("AI Limit Banner - Dark") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            AiLimitBanner(used: 3, limit: 3, isDark: true, onUpgrade: {})
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
            AiLimitBanner(used: 3, limit: 3, isDark: false, onUpgrade: {})
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
        }
    }
}
