//
//  FirstMealCelebrationView.swift
//  orie
//
//  Created by Shareef Evans on 14/04/2026.
//

import SwiftUI

struct FirstMealCelebrationView: View {
    var onClose: () -> Void

    private struct ConfettiPiece: Identifiable {
        let id = UUID()
        enum Shape { case triangle, square, circle }
        let shape: Shape
        let color: Color
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
        let rotation: Double
    }

    private let confetti: [ConfettiPiece] = [
        .init(shape: .triangle, color: Color(red: 0.9, green: 0.2, blue: 0.2), size: 16, x: 0.12, y: 0.08, rotation: 15),
        .init(shape: .circle,   color: Color(red: 1.0, green: 0.85, blue: 0.0), size: 10, x: 0.82, y: 0.10, rotation: 0),
        .init(shape: .square,   color: Color(red: 0.9, green: 0.2, blue: 0.2), size: 9,  x: 0.62, y: 0.13, rotation: 20),
        .init(shape: .circle,   color: Color(red: 0.2, green: 0.85, blue: 0.4), size: 8,  x: 0.22, y: 0.18, rotation: 0),
        .init(shape: .square,   color: Color(red: 1.0, green: 0.85, blue: 0.0), size: 11, x: 0.06, y: 0.38, rotation: 10),
        .init(shape: .triangle, color: Color(red: 0.0, green: 0.82, blue: 0.75), size: 18, x: 0.88, y: 0.42, rotation: -20),
        .init(shape: .triangle, color: Color(red: 0.9, green: 0.2, blue: 0.2), size: 15, x: 0.10, y: 0.55, rotation: -30),
        .init(shape: .triangle, color: Color(red: 0.9, green: 0.2, blue: 0.2), size: 14, x: 0.08, y: 0.72, rotation: 25),
        .init(shape: .triangle, color: Color(red: 0.0, green: 0.82, blue: 0.75), size: 14, x: 0.88, y: 0.70, rotation: -10),
        .init(shape: .square,   color: Color(red: 0.95, green: 0.15, blue: 0.55), size: 12, x: 0.14, y: 0.86, rotation: 15),
        .init(shape: .triangle, color: Color(red: 0.2, green: 0.55, blue: 0.95), size: 16, x: 0.50, y: 0.90, rotation: 5),
        .init(shape: .square,   color: Color(red: 1.0, green: 0.85, blue: 0.0), size: 10, x: 0.80, y: 0.84, rotation: -20),
        .init(shape: .square,   color: Color(red: 0.2, green: 0.55, blue: 0.95), size: 8,  x: 0.92, y: 0.90, rotation: 30),
        .init(shape: .circle,   color: Color(red: 0.2, green: 0.85, blue: 0.4), size: 9,  x: 0.35, y: 0.06, rotation: 0),
        .init(shape: .square,   color: Color(red: 0.9, green: 0.2, blue: 0.2), size: 8,  x: 0.72, y: 0.26, rotation: 45),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0x18/255, green: 0x18/255, blue: 0x18/255)
                    .ignoresSafeArea()

                // Confetti
                ForEach(confetti) { piece in
                    confettiShape(piece)
                        .position(
                            x: piece.x * geo.size.width,
                            y: piece.y * geo.size.height
                        )
                }

                // Content
                VStack(spacing: 0) {
                    Spacer()

                    Image("flame")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)

                    VStack(spacing: 16) {
                        Text("Wooooooohoooo!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.82, blue: 0.0))
                            .multilineTextAlignment(.center)

                        Text("Congratulations on logging\nyour first meal with Orie")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.bottom, 4)

                        Button(action: onClose) {
                            Text("Close Celebration")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                        }
                        #if os(iOS)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 100, style: .continuous))
                        #endif
                    }
                    .padding(.top, -80)

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func confettiShape(_ piece: ConfettiPiece) -> some View {
        Group {
            switch piece.shape {
            case .triangle:
                Triangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .rotationEffect(.degrees(piece.rotation))
            case .square:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .rotationEffect(.degrees(piece.rotation))
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            FirstMealCelebrationView(onClose: {})
                .presentationBackground(Color(red: 0x18/255, green: 0x18/255, blue: 0x18/255))
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.dark)
}
