//
//  ConsumedTabSkeleton.swift
//  orie
//

import SwiftUI

struct ConsumedTabSkeleton: View {
    let isDark: Bool
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            // Daily Intake card skeleton
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 22)
                    .padding(.top, 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 12)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 10)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 10)
                    }

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                }
                .padding(.top, 32)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground(isDark))
            .cornerRadius(32)

            // Entry rows skeleton
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 14)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 14)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground(isDark))
            .cornerRadius(32)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
