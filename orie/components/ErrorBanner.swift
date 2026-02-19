//
//  ErrorBanner.swift
//  orie
//
//  Created by Shareef Evans on 19/02/2026.
//

import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.red)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        #if os(iOS)
        .glassEffect(.regular.tint(Color.red.opacity(0.18)), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #else
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #endif
    }
}

#Preview("Error Banner") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack {
            Spacer()
            ErrorBanner(message: "Couldn't calculate calories for \"Grilled Chicken\". Please try again.")
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
        }
    }
}
