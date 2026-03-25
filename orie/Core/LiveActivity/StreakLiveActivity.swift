//
//  StreakLiveActivity.swift
//  orie
//
//  Dynamic Island presentation for streak counter
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct StreakLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StreakActivityAttributes.self) { context in
            // Lock screen / banner UI
            LockScreenStreakView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.2))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text("🔥")
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(context.state.streakDays)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text(context.state.streakDays == 1 ? "day" : "days")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Streak")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("continued!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("First entry logged today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                // Compact view - leading (left side)
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(context.state.streakDays)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // Compact view - trailing (right side)
                Text("streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            } minimal: {
                // Minimal view (when multiple activities are running)
                Text("🔥")
                    .font(.system(size: 16))
            }
            .keylineTint(Color.orange)
        }
    }
}

@available(iOS 16.2, *)
struct LockScreenStreakView: View {
    let context: ActivityViewContext<StreakActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.streakDays) day streak continued!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("Keep it up! First entry logged today.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(16)
    }
}
