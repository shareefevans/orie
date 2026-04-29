//
//  BottomNavigationBar.swift
//  orie
//
//  Created by Shareef Evans on 30/03/2026.
//

import SwiftUI

struct BottomNavigationBar: View {
    var isDark: Bool = false
    var isRecording: Bool = false
    var onFocusInput: (() -> Void)? = nil
    var onAskOrie: (() -> Void)? = nil
    var onTriggerMic: (() -> Void)? = nil
    var onTriggerCamera: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            // MARK: - Left nav button (plus / food entry)
            Button(action: { onFocusInput?() }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))
                    .frame(width: 50, height: 50)
            }
            .glassEffect(.regular.interactive())

            // MARK: - Center "Ask Orie..." pill
            Button(action: { onAskOrie?() }) {
                HStack(spacing: 8) {
                    Image(systemName: "circle.hexagonpath.fill")
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
            Button(action: { onTriggerMic?() }) {
                Image(systemName: isRecording ? "waveform.circle.fill" : "mic.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isRecording ? (isDark ? .black : .white) : Color.primaryText(isDark))
                    .frame(width: 50, height: 50)
                    .background(isRecording ? Color.yellow : Color.clear, in: Circle())
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(
                        isRecording ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                        value: isRecording
                    )
            }
            .glassEffect(.regular.interactive())

            // MARK: - Photo button
            Button(action: { onTriggerCamera?() }) {
                Image(systemName: "camera")
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
