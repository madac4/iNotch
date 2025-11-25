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
    
    /// Уровень заряда батареи (0-100)
    @Published private(set) var levelBattery: Float = 0.0
    
    /// Максимальная ёмкость батареи (обычно 100, но может снижаться)
    @Published private(set) var maxCapacity: Float = 0.0
    
    /// Идёт ли зарядка
    @Published private(set) var isCharging: Bool = false
        
    /// Первое обновление (для предотвращения уведомлений при запуске)
    @Published private(set) var isInitial: Bool = false
    
    /// Время до полной зарядки (в минутах)
    @Published private(set) var timeToFullCharge: Int = 0
        
    // MARK: - Приватные свойства
    
    /// Был ли в процессе зарядки (для отслеживания изменений)
    private var wasCharging: Bool = false
    
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
    
    /// Настраивает мониторинг событий батареи
    private func setupMonitor() {
        // Добавляем себя как observer в BatteryActivityManager
        managerBatteryId = managerBattery.addObserver { [weak self] event in
            guard let self = self else { return }
            self.handleBatteryEvent(event)
        }
    }
    
    // MARK: - Обработка событий
    
    /// Обрабатывает события батареи от BatteryActivityManager
    /// - Parameter event: Событие батареи
    private func handleBatteryEvent(_ event: BatteryEvent) {
        switch event {
        case .powerSourceChanged(let isCharging):
            // Изменение источника питания (подключение/отключение)
            withAnimation {
                self.isCharging = isCharging
            }
            
            // Показываем уведомление только если не первое обновление
            if !isInitial {
                notifyImportantChangeStatus()
            }
            
        case .batteryLevelChanged(let level):
            // Изменение уровня заряда
            withAnimation {
                self.levelBattery = level
            }
            
            // Проверяем низкий заряд
            if level < 10 && !isCharging && !isInitial {
                print("🪫 Предупреждение: Низкий заряд батареи (\(Int(level))%)")
                // TODO: Показать критическое уведомление
                notifyImportantChangeStatus()
            }

        case .isChargingChanged(let isCharging):
            // Изменение статуса зарядки
            withAnimation {
                self.isCharging = isCharging
            }
            
            wasCharging = isCharging
            
            if !isInitial {
                print("⚡️ Уведомление: \(isCharging ? "Зарядка началась" : "Зарядка остановлена")")
                notifyImportantChangeStatus()
            }
            
        case .timeToFullChargeChanged(let time):
            // Изменение времени до полной зарядки
            withAnimation {
                self.timeToFullCharge = time
            }
            
        case .maxCapacityChanged(let capacity):
            // Изменение максимальной ёмкости
            withAnimation {
                self.maxCapacity = capacity
            }
            
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
            self.maxCapacity = batteryInfo.maxCapacity
        }
    }
    
    /// Показывает уведомление о важном изменении статуса
    /// - Parameter delay: Задержка перед показом (в секундах)
    private func notifyImportantChangeStatus(delay: Double = 0.0) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            // TODO: Вызвать coordinator для показа уведомления
            // coordinator.toggleExpandingView(status: true, type: .battery)
            print("💡 Показываем уведомление о батарее")
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
