//
//  SettingsSliderRow.swift
//  iNotch
//
//  Created on 26.11.2025.
//

import SwiftUI

struct SettingsSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.1,
        format: @escaping (Double) -> String = { String(format: "%.1f", $0) }
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                Spacer()
                Text(format(value))
                    .fontWeight(.medium)
                    .monospaced()
                    .foregroundStyle(.secondary)
            }
            
            Slider(value: $value, in: range, step: step)
        }
        .padding(.vertical, 4)
    }
}

