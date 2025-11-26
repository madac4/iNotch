//
//  NotchEnums.swift
//  iNotch
//
//  Базовые перечисления (enums) для управления состояниями вырезки
//  Created by Petru Orbu on 18.11.2025.
//

import Foundation
import Defaults
import SwiftUI

// Используется для отслеживания текущего состояния UI
public enum NotchState {
    case closed
    case open
}

// Перечисление для стиля отображения
// Может быть расширено в будущем для разных визуальных стилей
public enum Style {
    case notch     // Стиль как у настоящей вырезки MacBook
    case floating  // Плавающий стиль (для будущих обновлений)
}


public enum WindowHeightMode: String, Defaults.Serializable {
    case matchMenuBar = "Match menubar height"
    case matchRealNotchSize = "Match actual notch size"
    case custom = "Custom height"
}

public enum BatteryEvent {
    case powerSourceChanged(isPluggedIn: Bool)
    case batteryLevelChanged(level: Float)
    case isChargingChanged(isCharging: Bool)
    case maxCapacityChanged(capacity: Float)
    case error(description: String)
}

enum BatteryError: Error {
    case powerSourceUnavailable
    case batteryInfoUnavailable(String)
    case batteryParameterMissing(String)
}

enum PanDirection {
    case left
    case right
    case up
    case down
}

enum SneakContentType {
    case battery
    case brightness
    case volume
    case backlight
    case music
}


// MARK: - Volume Settings
public enum VolumeIconMode: String, CaseIterable, Identifiable, Defaults.Serializable {
	case speakers = "Speakers"
	case outputDevice = "Output Device"

    public var id: String { self.rawValue }
}

public enum VolumeProgressColor: String, CaseIterable, Identifiable, Defaults.Serializable {
	case white = "White"
	case accent = "Accent"
	case decibel = "Decibel"

	public var id: String { self.rawValue }

	var displayColor: Color {
		switch self {
		case .white:
			return .white
		case .accent:
			return .accentColor
		case .decibel:
			return .green
		}
	}
}

public enum VolumeAnimationSpeed: String, CaseIterable, Identifiable, Defaults.Serializable {
	case smooth = "Smooth"
	case fast = "Fast"
	case instant = "Instant"

	public var id: String { self.rawValue }

	var animationDuration: TimeInterval {
		switch self {
		case .smooth:
			return 0.3
		case .fast:
			return 0.15
		case .instant:
			return 0.05
		}
	}
}
