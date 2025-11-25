//
//  Battery.swift
//  iNotch
//
//  Created by Petru Orbu on 18.11.2025.
//
//  Структура для хранения информации о батарее

import Foundation

struct BatteryInfo {
    let isCharging: Bool
    let currentCapacity: Float
    let maxCapacity: Float
    
    var percentage: Int {
        return Int((currentCapacity / maxCapacity) * 100)
    }

}
