//
//  DeviceConnectionSneakPeek.swift
//  iNotch
//
//  Created by Petru Orbu on 27.11.2025.
//

import SwiftUI
import Defaults

struct DeviceConnectionSneakPeek: View {
    let state: SneakPeekState
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                    
            if Defaults[.showConnectionState]{
                Text(state.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
                    
            Spacer()
            
//            if state.value != 0 {
                BatteryCircleView(battery: 41)
//            }
        }
    }
}

struct DeviceMovedView: View {
    let state: SneakPeekState
    @ObservedObject var coordinator: NotchCoordinator
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            // Device name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(state.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Return button
            Button(action: {
//                coordinator.reconnectToDevice()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.blue))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black)
        .cornerRadius(12)
    }
}

struct BatteryCircleView: View {
    let battery: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(batteryColor.opacity(0.3), lineWidth: 4)
                .frame(width: 16, height: 16)
            
            Circle()
                .trim(from: 0, to: CGFloat(battery) / 100)
                .stroke(batteryColor, style: StrokeStyle(lineWidth: 3, lineCap: .butt))
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(-90))
        }
    }
    
    private var batteryColor: Color {
        switch battery {
        case 0...10:
            return .red
        case 11...40:
            return .orange
        default:
            return .green
        }
    }
}

// MARK: - Previews

#Preview("Device Connection Sneak Peek") {
    VStack(spacing: 20) {
        DeviceConnectionSneakPeek(
            state: SneakPeekState(
                show: true,
                type: .deviceConnection,
                value: 50,
                icon: "airpodspro",
                title: "Petru's AirPods Pro"
            )
        )
        
        DeviceConnectionSneakPeek(
            state: SneakPeekState(
                show: true,
                type: .deviceConnection,
                value: 0,
                icon: "headphones",
                title: "Beats Studio Buds"
            )
        )
        .padding()
        .background(Color.black)
    }
    .frame(width: 300)
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Device Moved View") {
    VStack(spacing: 20) {
        DeviceMovedView(
            state: SneakPeekState(
                show: true,
                type: .deviceConnection,
                value: 0,
                icon: "airpodspro",
                title: "Petru's AirPods Pro"
            ),
            coordinator: NotchCoordinator.shared
        )
        
        DeviceMovedView(
            state: SneakPeekState(
                show: true,
                type: .deviceConnection,
                value: 0,
                icon: "headphones",
                title: "Beats Studio Buds"
            ),
            coordinator: NotchCoordinator.shared
        )
    }
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Battery Circle View") {
    HStack(spacing: 30) {
        VStack(spacing: 8) {
            BatteryCircleView(battery: 15)
            Text("Low (15%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        VStack(spacing: 8) {
            BatteryCircleView(battery: 35)
            Text("Medium (35%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        VStack(spacing: 8) {
            BatteryCircleView(battery: 75)
            Text("High (75%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        VStack(spacing: 8) {
            BatteryCircleView(battery: 100)
            Text("Full (100%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .background(Color.black)
}
