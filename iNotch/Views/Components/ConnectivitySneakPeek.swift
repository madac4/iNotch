import SwiftUI
import Defaults

struct DeviceConnectionSneakPeek: View {
    let state: SneakPeekState
    
    var isLowBattery: Bool {
        Defaults[.warnOnLowDeviceBattery] && state.value < Defaults[.lowDeviceBatteryThreshold] && !state.title.isEmpty
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(state.iconColor)

			if isLowBattery {
                Text(state.title)
                    .font(.subheadline)
                    .foregroundColor(state.titleColor)
			}
                                
            Spacer()
            
            BatteryCircleView(battery: state.value, color: isLowBattery ? .red : nil)
        }
    }
}

struct BatteryCircleView: View {
    let battery: Int
	let color: Color?
    
    var body: some View {
		VStack {
			ZStack {
				Circle()
					.stroke(
						(color != nil ? color! : batteryColor).opacity(0.3),
						lineWidth: 3
					)
					.frame(width: 16, height: 16)
				
				Circle()
					.trim(from: 0, to: CGFloat(battery) / 100)
					.stroke(
						(color != nil ? color! : batteryColor),
						style: StrokeStyle(lineWidth: 2, lineCap: .butt)
					)
					.frame(width: 16, height: 16)
					.rotationEffect(.degrees(-90))
			}
		}
    }
    
    private var batteryColor: Color {
        switch battery {
        case 0...20:
            return .red
        case 21...45:
            return .orange
        default:
            return .green
        }
    }
}
