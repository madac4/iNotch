//
//  Constants.swift
//  iNotch
//
//  Created by Petru Orbu on 18.11.2025.
//

import Defaults
import SwiftUI

extension Defaults.Keys {
    static let menubarIcon = Key<Bool>("menubarIcon", default: true)
    static let notchHeightMode = Key<WindowHeightMode>("notchHeightMode", default: WindowHeightMode.matchRealNotchSize)
    static let nonNotchHeightMode = Key<WindowHeightMode>("nonNotchHeightMode", default: WindowHeightMode.matchMenuBar)
    
    static let nonNotchHeight = Key<CGFloat>("nonNotchHeight", default: 32)
    static let notchHeight = Key<CGFloat>("notchHeight", default:32)
    static let cornerRadiusScaling = Key<Bool>("cornerRadiusScaling", default: true)
    static let extendHoverArea = Key<Bool>("extendHoverArea", default: false)
    
    static let inlineHUD = Key<Bool>("inlineHUD", default: false)
    static let enableGradient = Key<Bool>("enableGradient", default: false)
    
    /// Включить тактильную обратную связь
    static let enableHaptics = Key<Bool>("enableHaptics", default: true)

    /// Чувствительность жестов (чем меньше - тем чувствительнее)
    static let gestureSensitivity = Key<CGFloat>("gestureSensitivity", default: 50.0)

    /// Открывать notch по hover
    static let openNotchOnHover = Key<Bool>("openNotchOnHover", default: true)

    /// Минимальная длительность hover для открытия (секунды)
    static let minimumHoverDuration = Key<TimeInterval>("minimumHoverDuration", default: 0.5)

	static let showInDock = Key<Bool>("showInDock", default: false)

    // MARK: - Volume/Sound Settings
	static let volumeAnimationSpeed = Key<VolumeAnimationSpeed>("volumeAnimationSpeed", default: .fast)
	static let volumeProgressColor = Key<VolumeProgressColor>("volumeProgressColor", default: .white)
	static let volumeIconMode = Key<VolumeIconMode>("volumeIconMode", default: .speakers)
	static let enableVolumeSneakPeek = Key<Bool>("enableVolumeSneakPeek", default: true)
	static let volumeHUDDuration = Key<TimeInterval>("volumeHUDDuration", default: 1.5)
	static let showVolumePercentage = Key<Bool>("showVolumePercentage", default: true)
	static let showVolumeProgress = Key<Bool>("showVolumeProgress", default: false)
	static let showVolumeLabel = Key<Bool>("showVolumeLabel", default: false)

	// MARK: - Battery Settings
	static let showUnpluggedNotification = Key<Bool>("showUnpluggedNotification", default: true)
	static let enableBatterySneakPeek = Key<Bool>("enableBatterySneakPeek", default: true)
	static let playSoundOnLowBattery = Key<Bool>("playSoundOnLowBattery", default: true)
	static let showBatteryPercentage = Key<Bool>("showBatteryPercentage", default: true)
	static let playSoundOnUnplugged = Key<Bool>("playSoundOnUnplugged", default: false)
	static let batteryHUDDuration = Key<TimeInterval>("batteryHUDDuration", default: 5)
	static let lowBatteryThreshold = Key<Int>("lowBatteryThreshold", default: 10)
	static let warnOnLowBattery = Key<Bool>("warnOnLowBattery", default: true)
}
