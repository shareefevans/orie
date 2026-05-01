//
//  AlertPill.swift
//  orie
//

import SwiftUI

enum AlertSeverity { case warning, danger }

struct AlertPill: View {
    let message: String
    let severity: AlertSeverity
    @State private var isPulsing = false

    private var color: Color {
        severity == .danger ? .red : Color(red: 253/255, green: 181/255, blue: 0/255)
    }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 24, height: 24)
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
            }
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.leading, 4)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
        .onAppear { isPulsing = true }
    }
}
