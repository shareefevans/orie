//
//  BottomNavigationBar.swift
//  orie
//
//  Created by Shareef Evans on 30/03/2026.
//

import SwiftUI

struct BottomNavigationBar: View {
    var isDark: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // MARK: - Left nav button (Λ)
            Button(action: {}) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))
                    .frame(width: 50, height: 50)
            }
            .glassEffect(.regular.interactive())

            // MARK: - Center "Ask Orie..." pill
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.primaryText(isDark))
                    Text("Ask Orie...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.secondaryText(isDark))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
            }
            .glassEffect(.regular.interactive())

            // MARK: - Microphone button
            Button(action: {}) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                    .frame(width: 50, height: 50)
            }
            .glassEffect(.regular.interactive())

            // MARK: - Photo button
            Button(action: {}) {
                Image(systemName: "photo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                    .frame(width: 50, height: 50)
            }
            .glassEffect(.regular.interactive())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 15)
    }
}

#Preview {
    ZStack {
        Color(red: 24/255, green: 24/255, blue: 24/255)
            .ignoresSafeArea()
        VStack {
            Spacer()
            BottomNavigationBar(isDark: true)
        }
    }
    .preferredColorScheme(.dark)
}
