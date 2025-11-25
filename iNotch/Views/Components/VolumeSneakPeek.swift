//
//  VolumeSneakPeek.swift
//  iNotch
//
//  Created by Petru Orbu on 19.11.2025.
//

import SwiftUI

/// Sneak Peek уведомление громкости в стиле Dynamic Island
struct VolumeSneakPeekView: View {
    let state: SneakPeekState
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(state.iconColor)
            
            Spacer()
        
            Text(state.value > 0 && state.icon != "speaker.slash.fill" ? "\(state.value)%" : "Silent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(state.valueColor)
                .contentTransition(.numericText(value: Double(state.value)))
                .animation(.smooth(duration: 0.15), value: state.value)
                .frame(width: 36, alignment: .trailing)
                .monospacedDigit()
                .lineLimit(1)
            
        }
        .background(.black)
    }
}
