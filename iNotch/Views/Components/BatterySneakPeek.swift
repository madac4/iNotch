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
            Text(state.message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
        
            Text("\(state.percentage)%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(eventColor)
            
            eventIcon
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(eventColor)
            
        }
        .frame(width: getClosedNotchSize().width * 2, height: getClosedNotchSize().height)
        .background(.black)
    }
    
    // Иконка в зависимости от типа события
    var eventIcon: Image {
        switch state.type {
        case .battery:
            return Image(systemName: "battery.50")
        case .lowBattery:
            return Image(systemName: "battery.0")
        case .charging:
            return Image(systemName: "battery.50")
        case .fullyCharged:
            return Image(systemName: "battery.100")
        }
    }
    
    // Цвет в зависимости от события
    var eventColor: Color {
        switch state.type {
        case .battery:
            return .white
        case .lowBattery:
            return .red
        case .charging:
            return .green
        case .fullyCharged:
            return .green
        }
    }
}
