import SwiftUI
import Defaults

struct SoundSettingsView: View {
    @Default(.enableVolumeSneakPeek) var enableVolumeSneakPeek
    @Default(.volumeIconMode) var volumeIconMode
    @Default(.showVolumePercentage) var showVolumePercentage
    @Default(.showVolumeLabel) var showVolumeLabel
    @Default(.showVolumeProgress) var showVolumeProgress
    @Default(.volumeProgressColor) var volumeProgressColor
    @Default(.volumeHUDDuration) var volumeHUDDuration
    @Default(.volumeAnimationSpeed) var volumeAnimationSpeed
    
    @State private var selectedIconMode: VolumeIconMode = Defaults[.volumeIconMode]
    @State private var selectedProgressColor: VolumeProgressColor = Defaults[.volumeProgressColor]
    @State private var selectedAnimationSpeed: VolumeAnimationSpeed = Defaults[.volumeAnimationSpeed]
    
    var body: some View {
        Form {
            Section {
                SettingsSectionHeader(
                    icon: "speaker.2.fill",
                    iconColor: Color(red: 0.88, green: 0.29, blue: 0.89),
                    title: "Sound",
                    toggleKey: .enableVolumeSneakPeek
                )
                
                if enableVolumeSneakPeek {
                    HStack(spacing: 8) {
                        SettingsIconButton(
                            icon: "speaker.wave.2.fill",
                            label: "Show speaker",
                            isSelected: selectedIconMode == .speakers,
                            iconColor: .white
                        ) {
                            selectedIconMode = .speakers
                            Defaults[.volumeIconMode] = .speakers
                        }
                        
                        SettingsIconButton(
                            icon: "beats.headphones",
                            label: "Show device",
                            isSelected: selectedIconMode == .outputDevice,
                            iconColor: .white
                        ) {
                            selectedIconMode = .outputDevice
                            Defaults[.volumeIconMode] = .outputDevice
                        }
                    }
                    .padding(.vertical, 4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
            .animation(.smooth(duration: 0.3), value: enableVolumeSneakPeek)
            
            
            if enableVolumeSneakPeek {
                Section {
                    SettingsSectionTitle(title: "HUDs")
                    
                    SettingsToggleRow(label: "Show percentage", key: .showVolumePercentage)
                    SettingsToggleRow(label: "Show label", key: .showVolumeLabel)
                    
                    SettingsSliderRow(
                        label: "Duration",
                        value: $volumeHUDDuration,
                        range: 0...3,
                        step: 0.1,
                        format: { String(format: "%.1f s", $0) }
                    )
                    
                    SettingsToggleRow(label: "Show volume bar", key: .showVolumeProgress)
                    
                    if showVolumeProgress {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color Presets")
                            
                            HStack(spacing: 8) {
                                SettingsColorPresetButton(
                                    color: .white,
                                    label: "White",
                                    isSelected: selectedProgressColor == .white
                                ) {
                                    selectedProgressColor = .white
                                    Defaults[.volumeProgressColor] = .white
                                }
                                
                                SettingsColorPresetButton(
                                    color: .accentColor,
                                    label: "Accent",
                                    isSelected: selectedProgressColor == .accent
                                ) {
                                    selectedProgressColor = .accent
                                    Defaults[.volumeProgressColor] = .accent
                                }
                                
                                SettingsColorPresetButton(
                                    color: .red,
                                    label: "Decibel",
                                    isSelected: selectedProgressColor == .decibel
                                ) {
                                    selectedProgressColor = .decibel
                                    Defaults[.volumeProgressColor] = .decibel
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .padding(.vertical, 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Animation Speed")
                        
                        HStack(spacing: 8) {
                            SettingsIconButton(
                                icon: "tortoise.fill",
                                label: "Smooth",
                                isSelected: selectedAnimationSpeed == .smooth
                            ) {
                                selectedAnimationSpeed = .smooth
                                Defaults[.volumeAnimationSpeed] = .smooth
                            }
                            
                            SettingsIconButton(
                                icon: "hare.fill",
                                label: "Fast",
                                isSelected: selectedAnimationSpeed == .fast
                            ) {
                                selectedAnimationSpeed = .fast
                                Defaults[.volumeAnimationSpeed] = .fast
                            }
                            
                            SettingsIconButton(
                                icon: "bolt.fill",
                                label: "Instant",
                                isSelected: selectedAnimationSpeed == .instant
                            ) {
                                selectedAnimationSpeed = .instant
                                Defaults[.volumeAnimationSpeed] = .instant
                            }
                        }
                    }
                }
                .animation(.smooth(duration: 0.3), value: enableVolumeSneakPeek)
                .animation(.smooth(duration: 0.25), value: showVolumeProgress)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.smooth(duration: 0.3), value: enableVolumeSneakPeek)
        .navigationTitle("Sound")
        .onAppear {
            selectedIconMode = Defaults[.volumeIconMode]
            selectedProgressColor = Defaults[.volumeProgressColor]
            selectedAnimationSpeed = Defaults[.volumeAnimationSpeed]
        }
    }
}
