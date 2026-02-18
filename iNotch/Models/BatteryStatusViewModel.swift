//
//  BatteryStatusViewModel.swift
//  iNotch
//
//  ViewModel для управления отображением состояния батареи
//  Архитектура boring.notch с комментариями на русском
//
//  Ответственность:
//  - Подписка на BatteryActivityManager
//  - Обработка событий батареи
//  - Предоставление @Published свойств для UI
//  - Показ уведомлений через coordinator
//

import Cocoa
import Defaults
import Foundation
import IOKit.ps
import SwiftUI
import Combine

/// ViewModel для управления и мониторинга состояния батареи
class BatteryStatusViewModel: ObservableObject {
    
    // MARK: - Published свойства (автообновление UI)
    
    @Published private(set) var levelBattery: Float = 0.0
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isInitial: Bool = false
    
    /// Менеджер батареи
    private let managerBattery = BatteryManager.shared
    
    /// ID нашего observer в BatteryActivityManager
    private var managerBatteryId: Int?
    
    // MARK: - Singleton
    
    static let shared = BatteryStatusViewModel()
    
    // MARK: - Инициализация
    
    private init() {
        setupPowerStatus()
        setupMonitor()
    }
    
    /// Настраивает начальное состояние питания
    private func setupPowerStatus() {
        let batteryInfo = managerBattery.initializeBatteryInfo()
        updateBatteryInfo(batteryInfo)
        isInitial = true
    }
    
    private func setupMonitor() {
        managerBatteryId = managerBattery.addObserver { [weak self] event in
            guard let self = self else { return }
            self.handleBatteryEvent(event)
        }
    }
    

    private func handleBatteryEvent(_ event: BatteryEvent) {
        switch event {
        case .powerSourceChanged(let isCharging):
            withAnimation {
                self.isCharging = isCharging
            }
            
        case .batteryLevelChanged(let level):
            withAnimation {
                self.levelBattery = level
            }
            
        case .isChargingChanged(let isCharging):
            // Изменение статуса зарядки (duplicate of powerSourceChanged, but handle for completeness)
            withAnimation {
                self.isCharging = isCharging
            }
            
        case .maxCapacityChanged:
            // Ignored - not used
            break
            
        case .error(let description):
            // Ошибка
            print("⚠️ Ошибка батареи: \(description)")
        }
        
        // После первого обновления - снимаем флаг
        if isInitial {
            isInitial = false
        }
    }
    
    /// Обновляет всю информацию о батарее
    /// - Parameter batteryInfo: Новая информация о батарее
    private func updateBatteryInfo(_ batteryInfo: BatteryInfo) {
        withAnimation {
            self.levelBattery = batteryInfo.currentCapacity
            self.isCharging = batteryInfo.isCharging
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("🔌 Очистка мониторинга батареи...")
        if let managerBatteryId = managerBatteryId {
            managerBattery.removeObserver(byId: managerBatteryId)
        }
    }
}
