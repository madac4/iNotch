//
//  NotchSpaceManager.swift
//  iNotch
//
//  Created by Petru Orbu on 18.11.2025.
//
//  Менеджер для управления пространством вырезки
//  Создаёт специальное пространство на максимальном уровне
//

import Foundation

class NotchSpaceManager {
    static let shared = NotchSpaceManager()
    
    let notchSpace: CGSSpace
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private init() {
        notchSpace = CGSSpace(level: 2147483647)
        print("✅ NotchSpaceManager: Создано пространство с максимальным уровнем")
    }
    
    deinit{
        print("🗑️ NotchSpaceManager: Уничтожается")
    }
}
