//
//  SettingsSectionTitle.swift
//  iNotch
//
//  Created on 26.11.2025.
//

import SwiftUI

struct SettingsSectionTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.vertical, 4)
    }
}

