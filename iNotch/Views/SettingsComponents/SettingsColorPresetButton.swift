//
//  SettingsColorPresetButton.swift
//  iNotch
//
//  Created on 26.11.2025.
//

import SwiftUI

struct SettingsColorPresetButton: View {
    let color: Color
    let label: String
    let isSelected: Bool
    let progress: CGFloat
    let action: () -> Void
    
    init(color: Color, label: String, isSelected: Bool, progress: CGFloat = 0.6, action: @escaping () -> Void) {
        self.color = color
        self.label = label
        self.isSelected = isSelected
        self.progress = progress
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                GeometryReader { geometry in
                    let filledWidth = geometry.size.width * progress
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: filledWidth, height: 6)
                    }
                }
                .frame(height: 6)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 24)
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
                .foregroundStyle(isSelected ? .white : .secondary)
                .fontWeight(.medium)
        }
    }
}

