//
//  BatteryComponents.swift
//  iNotch
//
//  Компоненты батареи в стиле iPhone 15 Pro Dynamic Island
//

import SwiftUI
import Defaults

/// Sneak Peek уведомление батареи в стиле Dynamic Island
struct BatterySneakPeekView: View {
    let state: SneakPeekState
    
    var body: some View {
        HStack(spacing: 4) {
            Text(state.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
        
            Text("\(state.value)%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(state.valueColor)
            
            Image(systemName: state.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(state.iconColor)
            
        }
        .background(.black)
    }
}
