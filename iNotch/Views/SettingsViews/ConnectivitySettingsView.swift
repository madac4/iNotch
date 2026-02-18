import SwiftUI
import Defaults

struct ConnectivitySettingsView: View {
    @Default(.playSoundOnLowDeviceBattery) var playSoundOnLowDeviceBattery
	@Default(.enableConnectivitySneakPeek) var enableConnectivitySneakPeek
    @Default(.showDisconnectNotification) var showDisconnectNotification
	@Default(.lowDeviceBatteryThreshold) var lowDeviceBatteryThreshold
    @Default(.connectivityHUDDuration) var connectivityHUDDuration
    @Default(.warnOnLowDeviceBattery) var warnOnLowDeviceBattery
    @Default(.deviceIconMode) var deviceIconMode
    
    @State private var selectedIconMode: DeviceIconMode = Defaults[.deviceIconMode]

    var body: some View {
        Form {
            Section {
               SettingsSectionHeader(
                    icon: "airpodsmax",
                    iconColor: Color(red: 0.23, green: 0.8, blue: 0.59),
                    title: "Connectivity",
                    toggleKey: .enableConnectivitySneakPeek
                )

				if enableConnectivitySneakPeek {
                    SettingsSliderRow(
                        label: "Duration",
                        value: $connectivityHUDDuration,
                        range: 0...10,
                        step: 1,
                        format: { String(format: "%.1f s", $0) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))

                    SettingsToggleRow(label: "Show disconnect notification", key: .showDisconnectNotification)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))

                    SettingsToggleRow(label: "Warn on low battery", key: .warnOnLowDeviceBattery)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))

					if warnOnLowDeviceBattery {
						SettingsSliderRow(
							label: "Low battery threshold",
							value: Binding(
								get: { Double(lowDeviceBatteryThreshold) },
								set: { lowDeviceBatteryThreshold = Int($0) }
							),
							range: 5...60,
								step: 5,
								format: { String(format: "%.0f%%", $0) }
						)
						.transition(.asymmetric(
							insertion: .move(edge: .top).combined(with: .opacity),
							removal: .move(edge: .top).combined(with: .opacity)
						))
                        SettingsToggleRow(
                            label: "Play sound on low battery",
                            key: .playSoundOnLowDeviceBattery
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
					}

                    HStack(spacing: 8) {
                        SettingsIconButton(
                            icon: "airpodspro",
                            label: "Symbols",
                            isSelected: selectedIconMode == .symbol,
                        ) {
                            selectedIconMode = .symbol
                            Defaults[.deviceIconMode] = .symbol
                        }
                        SettingsIconButton(
                            icon: "move.3d",
                            label: "3D Models",
                            isSelected: selectedIconMode == .model3D,
                        ) {
                            selectedIconMode = .model3D
                            Defaults[.deviceIconMode] = .model3D
                        }
                    }
                }
            }
			.animation(.smooth(duration: 0.3), value: enableConnectivitySneakPeek)
			.animation(.smooth(duration: 0.25), value: warnOnLowDeviceBattery)
        }
		.animation(.smooth(duration: 0.3), value: enableConnectivitySneakPeek)
        .navigationTitle("Connectivity")
    }
}
