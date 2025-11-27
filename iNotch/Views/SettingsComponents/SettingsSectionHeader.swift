//
//  SettingsSectionHeader.swift
//  iNotch
//
//  Created on 26.11.2025.
//

import SwiftUI
import Defaults

struct SettingsSectionHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let toggleKey: Defaults.Key<Bool>?
    
    init(icon: String, iconColor: Color, title: String, toggleKey: Defaults.Key<Bool>? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.toggleKey = toggleKey
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let toggleKey = toggleKey {
                Defaults.Toggle("", key: toggleKey)
            }
        }
        .padding(.vertical, 4)
    }
}

