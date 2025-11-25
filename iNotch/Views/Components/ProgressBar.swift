//
//  ProgressBar.swift
//  iNotch
//
//  Простой progress bar без drag функционала
//

import SwiftUI

struct ProgressBar: View {
    let value: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Фон (серая дорожка)
                Capsule()
                    .fill(.tertiary)
                
                // Заполненная часть (белая с градиентом)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.5)],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: max(0, min(geo.size.width * value, geo.size.width)))
                    .shadow(color: .white.opacity(0.5), radius: 8, x: 3)
                    .opacity(value.isZero ? 0 : 1)
                    .animation(.smooth(duration: 0.15), value: value)  // ← Плавная анимация
            }
        }
        .frame(height: 5)
    }
}
