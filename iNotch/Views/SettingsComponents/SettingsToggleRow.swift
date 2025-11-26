//
//  SettingsToggleRow.swift
//  iNotch
//
//  Created on 26.11.2025.
//

import SwiftUI
import Defaults

struct SettingsToggleRow: View {
    let label: String
    let key: Defaults.Key<Bool>
    
    var body: some View {
        Defaults.Toggle(label, key: key)
            .padding(.vertical, 4)
    }
}

