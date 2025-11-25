//
//  NotchShape.swift
//  iNotch
//
//  Рисует форму вырезки с закруглёнными углами
//
//  Created by Petru Orbu on 18.11.2025.
//

import SwiftUI

struct NotchShape: Shape {
    private var topCornerRadius: CGFloat
    private var bottomCornerRadius: CGFloat
    
    init(
        topCornerRadius: CGFloat? = nil,
        bottomCornerRadius: CGFloat? = nil
    ) {
        self.topCornerRadius = topCornerRadius ?? 6
        self.bottomCornerRadius = bottomCornerRadius ?? 14
    }
    
    /// Позволяет SwiftUI плавно анимировать изменения радиусов
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get{
            .init(topCornerRadius, bottomCornerRadius)
        }
        
        set{
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }
    
    /// Создаёт путь для рисования формы вырезки
    func path(in rect: CGRect) -> Path{
        var path = Path()
        
        // Начинаем с верхнего левого угла
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // ЛЕВАЯ СТОРОНА
        // Верхнее скругление
        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY + topCornerRadius
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY
            )
        )
        
        // Линия вниз
        path.addLine(
            to: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY - bottomCornerRadius)
        )
        
        // Нижнее скругление
        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius + bottomCornerRadius,
                y: rect.maxY
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY
            )
        )
        
        // НИЖНЯЯ СТОРОНА
        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius - bottomCornerRadius,
                y: rect.maxY
            )
        )
        
        
        // ПРАВАЯ СТОРОНА
        // Нижнее скругление
        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY
            )
        )
        
        // Линия вверх
        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY + topCornerRadius
            )
        )

        // Верхнее скругление
        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY
            )
        )

        // Замыкаем путь
        path.addLine(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )
        
        return path
    }
}

#Preview{
    NotchShape(topCornerRadius: 6, bottomCornerRadius: 14).frame(width: 200, height: 32).padding(10)
}
