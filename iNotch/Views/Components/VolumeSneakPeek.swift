//
//  VolumeSneakPeek.swift
//  iNotch
//
//  Created by Petru Orbu on 19.11.2025.
//

import SwiftUI
import Defaults

/// Sneak Peek уведомление громкости в стиле Dynamic Island
struct VolumeSneakPeekView: View {
    let state: SneakPeekState

	@Default(.showVolumePercentage) var showVolumePercentage
	@Default(.volumeAnimationSpeed) var volumeAnimationSpeed
	@Default(.volumeProgressColor) var volumeProgressColor
	@Default(.showVolumeProgress) var showVolumeProgress
	@Default(.showVolumeLabel) var showVolumeLabel
	@Default(.volumeIconMode) var volumeIconMode

	private let volumeManager = VolumeManager.shared
    
    var body: some View {
		HStack(spacing: 4) {
			iconView
			
			if showVolumeLabel {
				labelView
			}
			
			Spacer()
			
			if showVolumeProgress {
				progressView
			}
			if showVolumePercentage {
				percentageView
			}
		}
    }

	@ViewBuilder
	private var iconView: some View {
		Group {
			switch volumeIconMode {
			case .speakers:
				Image(systemName: state.icon)
					.font(.system(size: 14, weight: .semibold))
					.foregroundColor(state.iconColor)
			case .outputDevice:
				outputDeviceIcon
			}
		}
		.animation(.smooth(duration: volumeAnimationSpeed.animationDuration), value: state.value)
	}

	@ViewBuilder
	private var outputDeviceIcon: some View {
		Image(systemName: volumeManager.getDeviceIcon() ?? "airpodspro")
			.font(.system(size: 14, weight: .semibold))
			.foregroundColor(state.iconColor)
	}

	@ViewBuilder
	private var labelView: some View {
		Text("Volume")
			.font(.system(size: 12, weight: .medium))
			.foregroundColor(state.valueColor)
	}

	@ViewBuilder
	private var percentageView: some View {
		Text(state.value > 0 && state.icon != "speaker.slash.fill" ? "\(state.value)%" : "Silent")
			.font(.system(size: 12, weight: .medium))
			.foregroundColor(state.valueColor)
			.contentTransition(.numericText(value: Double(state.value)))
			.animation(.smooth(duration: volumeAnimationSpeed.animationDuration), value: state.value)
			.frame(width: 36, alignment: .trailing)
			.monospacedDigit()
			.lineLimit(1)
	}

	@ViewBuilder
	private var progressView: some View {
		GeometryReader { geometry in
			ZStack(alignment: .leading) {
				RoundedRectangle(cornerRadius: 2)
					.fill(Color.white.opacity(0.2))
                    .frame(height: 4)

				RoundedRectangle(cornerRadius: 2)
					.fill(progressBarColor)
					.frame(width: geometry.size.width * CGFloat(state.value) / 100, height: 4)
					.animation(.smooth(duration: volumeAnimationSpeed.animationDuration), value: state.value)
			}
		}
		.frame(width: 64, height: 4)
	}

	private var progressBarColor: Color {
        switch volumeProgressColor {
        case .white:
            return .white
        case .accent:
            return .accentColor
        case .decibel:
            return decibelColor(for: state.value)
        }
    }

	private func decibelColor(for volume: Int) -> Color {
        switch volume {
        case 0:
            return .gray
        case 1...33:
            return .green
        case 34...66:
            return .yellow
        case 67...100:
            return .red
        default:
            return .white
        }
    }
}
