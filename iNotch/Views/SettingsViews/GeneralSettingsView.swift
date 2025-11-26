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
    @Default(.menubarIcon) var showMenuBarIcon
    @Default(.showInDock) var showInDock
    
    var body: some View {
        Form {
            Section {
                Defaults.Toggle("Menubar icon", key: .menubarIcon)
                
                Defaults.Toggle("Show in Dock", key: .showInDock)
                    .onChange(of: showInDock) { _, newValue in
                        updateDockVisibility(showInDock: newValue)
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