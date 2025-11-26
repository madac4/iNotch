//
//  SettingsNavigationItem.swift
//  iNotch
//
//  Reusable navigation item component for settings sidebar
//

import SwiftUI

struct SettingsNavigationItem<Destination>: View where Destination: Hashable {
    let value: Destination
    let icon: String
    let title: String
    let iconColor: Color
    let gradientColors: [Color]
    let gradientDirection: GradientDirection
    
    enum GradientDirection {
        case linear(startPoint: UnitPoint, endPoint: UnitPoint)
        case radial(center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat)
    }
    
    init(
        value: Destination,
        icon: String,
        title: String,
        iconColor: Color = .white,
        gradientColors: [Color] = [Color.purple, Color.purple.opacity(0.6)],
        gradientDirection: GradientDirection = .radial(center: .center, startRadius: 5, endRadius: 15)
    ) {
        self.value = value
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.gradientColors = gradientColors
        self.gradientDirection = gradientDirection
    }
    
    var body: some View {
        NavigationLink(value: value) {
            HStack(spacing: 8) {
                iconView
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        Image(systemName: icon)
            .foregroundStyle(iconColor)
            .frame(width: 24, height: 24)
            .font(.callout)
            .background(backgroundGradient)
            .cornerRadius(8)
    }
    
    @ViewBuilder
    private var backgroundGradient: some View {
        switch gradientDirection {
        case .linear(let startPoint, let endPoint):
            LinearGradient(
                colors: gradientColors,
                startPoint: startPoint,
                endPoint: endPoint
            )
        case .radial(let center, let startRadius, let endRadius):
            RadialGradient(
                colors: gradientColors,
                center: center,
                startRadius: startRadius,
                endRadius: endRadius
            )
        }
    }
}

// MARK: - Convenience Initializers

extension SettingsNavigationItem {
    /// Creates a navigation item with a linear gradient (for Sound, etc.)
    static func withLinearGradient(
        value: Destination,
        icon: String,
        title: String,
        iconColor: Color = .white,
        gradientColors: [Color],
        startPoint: UnitPoint = .bottom,
        endPoint: UnitPoint = .top
    ) -> SettingsNavigationItem {
        SettingsNavigationItem(
            value: value,
            icon: icon,
            title: title,
            iconColor: iconColor,
            gradientColors: gradientColors,
            gradientDirection: .linear(startPoint: startPoint, endPoint: endPoint)
        )
    }
    
    /// Creates a navigation item with a radial gradient
    static func withRadialGradient(
        value: Destination,
        icon: String,
        title: String,
        iconColor: Color = .white,
        gradientColors: [Color] = [Color.purple, Color.purple.opacity(0.6)],
        center: UnitPoint = .center,
        startRadius: CGFloat = 5,
        endRadius: CGFloat = 15
    ) -> SettingsNavigationItem {
        SettingsNavigationItem(
            value: value,
            icon: icon,
            title: title,
            iconColor: iconColor,
            gradientColors: gradientColors,
            gradientDirection: .radial(center: center, startRadius: startRadius, endRadius: endRadius)
        )
    }
}
