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
    }
    
    deinit{
        print("🗑️ NotchSpaceManager: Уничтожается")
    }
}
