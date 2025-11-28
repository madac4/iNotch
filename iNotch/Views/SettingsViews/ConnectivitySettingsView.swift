//
//  BatterySettingsView.swift
//  iNotch
//
//  Created by Petru Orbu on 26.11.2025.
//

import SwiftUI
import Defaults

struct ConnectivitySettingsView: View {
	@Default(.showUnpluggedNotification) var showUnpluggedNotification
	@Default(.enableBatterySneakPeek) var enableBatterySneakPeek
    @Default(.playSoundOnLowBattery) var playSoundOnLowBattery
    @Default(.showBatteryPercentage) var showBatteryPercentage
	@Default(.playSoundOnUnplugged) var playSoundOnUnplugged
    @Default(.lowBatteryThreshold) var lowBatteryThreshold
    @Default(.batteryHUDDuration) var batteryHUDDuration
    @Default(.warnOnLowBattery) var warnOnLowBattery

    var body: some View {
        Form {
            Section {
               SettingsSectionHeader(
                    icon: "bolt.fill",
                    iconColor: .orange,
                    title: "Battery",
                    toggleKey: .enableBatterySneakPeek
                )

				if enableBatterySneakPeek {
                    SettingsSliderRow(
                        label: "Duration",
                        value: $batteryHUDDuration,
                        range: 0...10,
                        step: 0.5,
                        format: { String(format: "%.1f s", $0) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))

                    SettingsToggleRow(label: "Show unplugged notification", key: .showUnpluggedNotification)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))

                    SettingsToggleRow(label: "Warn on low battery", key: .warnOnLowBattery)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))

					if warnOnLowBattery {
						SettingsSliderRow(
							label: "Low battery threshold",
							value: Binding(
								get: { Double(lowBatteryThreshold) },
								set: { lowBatteryThreshold = Int($0) }
							),
							range: 5...30,
								step: 5,
								format: { String(format: "%.0f%%", $0) }
						)
						.transition(.asymmetric(
							insertion: .move(edge: .top).combined(with: .opacity),
							removal: .move(edge: .top).combined(with: .opacity)
						))
					}

					SettingsToggleRow(
                        label: "Play sound on low battery",
                        key: .playSoundOnLowBattery
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))

					SettingsToggleRow(
                        label: "Play sound on unplugged",
                        key: .playSoundOnUnplugged
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    
                    SettingsToggleRow(label: "Show percentage", key: .showBatteryPercentage)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
			.animation(.smooth(duration: 0.3), value: enableBatterySneakPeek)
			.animation(.smooth(duration: 0.25), value: warnOnLowBattery)
        }
		.animation(.smooth(duration: 0.3), value: enableBatterySneakPeek)
        .navigationTitle("Battery")
    }
}
