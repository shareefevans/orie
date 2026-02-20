//
//  AwardBanner.swift
//  orie
//
//  Created by Shareef Evans on 20/02/2026.
//

import SwiftUI

struct AwardBanner: View {
    let achievement: Achievement
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: achievement.image)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 32, height: 32)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                case .failure:
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.yellow)
                        .frame(width: 32, height: 32)
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Congratulations!")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("You unlocked an award")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text("View")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        #if os(iOS)
        .glassEffect(.regular.tint(Color.yellow.opacity(0.18)), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #else
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        #endif
    }
}

#Preview("Award Banner") {
    ZStack {
        Color.white
            .ignoresSafeArea()

        VStack {
            Spacer()
            AwardBanner(achievement: Achievement(
                achievementId: "1",
                name: "First Steps",
                description: "Log your first meal",
                category: "nutrition",
                image: "",
                currentProgress: 1,
                target: 1,
                percentage: 100,
                isUnlocked: true,
                unlockedAt: nil
            ), onTap: {})
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
    }
}
