//
//  Constants.swift
//  iNotch
//
//  Created by Petru Orbu on 18.11.2025.
//

import Defaults
import SwiftUI

extension Defaults.Keys {
    static let nonNotchHeightMode = Key<WindowHeightMode>("nonNotchHeightMode", default: WindowHeightMode.matchMenuBar)
    static let notchHeightMode = Key<WindowHeightMode>("notchHeightMode", default: WindowHeightMode.matchRealNotchSize)
    
    static let cornerRadiusScaling = Key<Bool>("cornerRadiusScaling", default: true)
    static let extendHoverArea = Key<Bool>("extendHoverArea", default: false)
    static let nonNotchHeight = Key<CGFloat>("nonNotchHeight", default: 32)
    static let notchHeight = Key<CGFloat>("notchHeight", default:32)

    static let gestureSensitivity = Key<CGFloat>("gestureSensitivity", default: 50.0)

    // MARK: - General Settings
	static let animationSpeed = Key<AnimationSpeed>("animationSpeed", default: .fast)
    static let hoverDelay = Key<TimeInterval>("minimumHoverDuration", default: 0.5)
    static let openNotchOnHover = Key<Bool>("openNotchOnHover", default: true)
    static let showMenuBarIcon = Key<Bool>("showMenuBarIcon", default: true)
	static let enableGestures = Key<Bool>("enableGestures", default: true)
    static let enableHaptics = Key<Bool>("enableHaptics", default: true)
	static let allowGestures = Key<Bool>("allowGestures", default: true)
    static let openOnHover = Key<Bool>("openOnHover", default: false)
	static let showInDock = Key<Bool>("showInDock", default: false)

    // MARK: - Volume/Sound Settings
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

	// MARK: - Device Connection Settings
	static let enableConnectivitySneakPeek = Key<Bool>("enableDeviceConnectionSneakPeek", default: true)
	static let connectivityHUDDuration = Key<TimeInterval>("deviceConnectionHUDDuration", default: 3.0)
	static let playSoundOnLowDeviceBattery = Key<Bool>("playSoundOnLowDeviceBattery", default: true)
	static let showDisconnectNotification = Key<Bool>("showDisconnectNotification", default: false)
	static let lowDeviceBatteryThreshold = Key<Int>("lowDeviceBatteryThreshold", default: 10)
	static let warnOnLowDeviceBattery = Key<Bool>("warnOnLowDeviceBattery", default: true)
	static let deviceIconMode = Key<DeviceIconMode>("deviceIconMode", default: .symbol)
}
