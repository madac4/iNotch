//
//  GeneralSettingsView.swift
//  iNotch
//
//  Created by Petru Orbu on 26.11.2025.
//

import SwiftUI
import Defaults
import AppKit

struct GeneralSettingsView: View {
    @Default(.showMenuBarIcon) var showMenuBarIcon
    @Default(.animationSpeed) var animationSpeed
    @Default(.showInDock) var showInDock

	@State private var selectedAnimationSpeed: AnimationSpeed = Defaults[.animationSpeed]
    
    var body: some View {
        Form {
            Section {
                Defaults.Toggle("Menubar icon", key: .showMenuBarIcon)
                Defaults.Toggle("Show in Dock", key: .showInDock)
                Defaults.Toggle("Open notch on hover", key: .openOnHover)
				Defaults.Toggle("Allow gestures", key: .allowGestures)
                    .onChange(of: showInDock) { _, newValue in
                        updateDockVisibility(showInDock: newValue)
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
                                Defaults[.animationSpeed] = .smooth
                            }
                            
                            SettingsIconButton(
                                icon: "hare.fill",
                                label: "Fast",
                                isSelected: selectedAnimationSpeed == .fast
                            ) {
                                selectedAnimationSpeed = .fast
                                Defaults[.animationSpeed] = .fast
                            }
                            
                            SettingsIconButton(
                                icon: "bolt.fill",
                                label: "Instant",
                                isSelected: selectedAnimationSpeed == .instant
                            ) {
                                selectedAnimationSpeed = .instant
                                Defaults[.animationSpeed] = .instant
                            }
                        }
                    }
            } header: {
                Text("General")
            }
        }
        .navigationTitle("General")
        .toolbar {
            Button("Quit app") {
                NSApp.terminate(nil)
            }
            .controlSize(.extraLarge)
        }
        .onAppear {
            updateDockVisibility(showInDock: showInDock)
        }
    }
    
    private func updateDockVisibility(showInDock: Bool) {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
}
