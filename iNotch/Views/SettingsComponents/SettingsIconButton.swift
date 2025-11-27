//
//  SettingsIconButton.swift
//  iNotch
//
//  Created on 26.11.2025.
//

import SwiftUI

struct SettingsIconButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let iconColor: Color?
    let action: () -> Void
    
    init(
        icon: String,
        label: String,
        isSelected: Bool,
        iconColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.isSelected = isSelected
        self.iconColor = iconColor
        self.action = action
    }
    
    private var resolvedIconColor: Color {
        if let iconColor = iconColor {
            return iconColor
        }
        return isSelected ? .primary : .secondary
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(resolvedIconColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.cyan : Color.clear,
                                lineWidth: 2
                            )
                    )
            }
            .buttonStyle(.plain)
            
            Text(label)
                .font(.callout)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .fontWeight(.medium)
        }
    }
}

