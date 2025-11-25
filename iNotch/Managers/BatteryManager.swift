//
//  BatteryManager.swift
//  iNotch
//
//  Created by Petru Orbu on 18.11.2025.
//
//  Менеджер для мониторинга состояния батареи
//  Использует IOKit для получения информации о батарее

//
//  BatteryActivityManager.swift
//  iNotch
//
//  Менеджер активности батареи - низкоуровневая работа с IOKit
//  Архитектура из boring.notch с комментариями на русском
//
//  Ответственность:
//  - Мониторинг изменений батареи через IOKit
//  - Генерация событий (BatteryEvent)
//  - Управление подписчиками (Observer pattern)
//  - Очередь уведомлений для предотвращения спама
//

import Foundation
import IOKit.ps

/// Менеджер для мониторинга и управления состоянием батареи
/// Использует IOKit framework для получения информации о питании
class BatteryManager {
    
    // Singleton - один экземпляр на всё приложение
    static let shared = BatteryManager()
    
    // MARK: - Callbacks (опциональные замыкания для быстрого доступа)
    
    /// Вызывается при изменении уровня батареи
    var onBatteryLevelChange: ((Float) -> Void)?
    
    /// Вызывается при изменении максимальной ёмкости
    var onMaxCapacityChange: ((Float) -> Void)?
    
    /// Вызывается при изменении режима энергосбережения
    var onPowerModeChange: ((Bool) -> Void)?
    
    /// Вызывается при изменении источника питания (подключение/отключение)
    var onPowerSourceChange: ((Bool) -> Void)?
    
    /// Вызывается при изменении статуса зарядки
    var onChargingChange: ((Bool) -> Void)?
    
    /// Вызывается при изменении времени до полной зарядки
    var onTimeToFullChargeChange: ((Int) -> Void)?
    
    // MARK: - Приватные свойства
    
    /// Run loop source для мониторинга изменений питания
    private var batterySource: CFRunLoopSource?
    
    /// Массив наблюдателей (подписчиков на события)
    private var observers: [(BatteryEvent) -> Void] = []
    
    /// Предыдущее состояние батареи (для сравнения изменений)
    private var previousBatteryInfo: BatteryInfo?
    
    /// Очередь уведомлений (для предотвращения спама)
    private var notificationQueue: [BatteryEvent] = []
    
    /// Флаг: идёт ли сейчас обработка уведомлений
    private var isProcessingNotifications = false
    
    // MARK: - Типы данных
    
    /// Информация о батарее по умолчанию (используется при ошибках)
    private let defaultBatteryInfo = BatteryInfo(
        isCharging: false,
        currentCapacity: 0,
        maxCapacity: 0,
    )
    
    // MARK: - Инициализация
    
    private init() {
        startMonitoring()
    }

    
    // MARK: - Мониторинг
    
    /// Запускает мониторинг изменений батареи через IOKit
    func startMonitoring() {
        // Получаем начальное состояние
        previousBatteryInfo = getBatteryInfo()
        
        // Создаём context для callback
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // Создаём run loop source для уведомлений о питании
        batterySource = IOPSNotificationCreateRunLoopSource({ context in
            // Этот callback вызывается при любом изменении источника питания
            guard let context = context else { return }
            let manager = Unmanaged<BatteryManager>.fromOpaque(context).takeUnretainedValue()
            
            // Обрабатываем изменения на главном потоке
            DispatchQueue.main.async {
                manager.handlePowerSourceChange()
            }
        }, context).takeRetainedValue()
        
        // Добавляем source в текущий run loop
        if let source = batterySource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    /// Останавливает мониторинг
    func stopMonitoring() {
        if let source = batterySource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            batterySource = nil
        }
    }
    
    /// Обрабатывает изменение источника питания
    private func handlePowerSourceChange() {
        let newInfo = getBatteryInfo()
        
        guard let previousInfo = previousBatteryInfo else {
            previousBatteryInfo = newInfo
            return
        }
        
        // Сравниваем с предыдущим состоянием и генерируем события
        
        // Изменение источника питания (подключение/отключение зарядки)
        if previousInfo.isCharging != newInfo.isCharging {
            onPowerSourceChange?(newInfo.isCharging)
            queueNotification(.powerSourceChanged(isPluggedIn: newInfo.isCharging))
        }
        
        // Изменение уровня заряда
        if previousInfo.currentCapacity != newInfo.currentCapacity {
            onBatteryLevelChange?(newInfo.currentCapacity)
            queueNotification(.batteryLevelChanged(level: newInfo.currentCapacity))
        }
        
        // Изменение статуса зарядки
        if previousInfo.isCharging != newInfo.isCharging {
            onChargingChange?(newInfo.isCharging)
            queueNotification(.isChargingChanged(isCharging: newInfo.isCharging))
        }
        
        // Изменение максимальной ёмкости
        if previousInfo.maxCapacity != newInfo.maxCapacity {
            onMaxCapacityChange?(newInfo.maxCapacity)
            queueNotification(.maxCapacityChanged(capacity: newInfo.maxCapacity))
        }
        
        // Сохраняем новое состояние
        previousBatteryInfo = newInfo
    }
    
    // MARK: - Получение информации о батарее
    
    /// Инициализирует и возвращает текущую информацию о батарее
    /// - Returns: Структура BatteryInfo с актуальными данными
    func initializeBatteryInfo() -> BatteryInfo {
        let info = getBatteryInfo()
        previousBatteryInfo = info
        return info
    }
    
    /// Получает текущую информацию о батарее через IOKit
    /// - Returns: Структура BatteryInfo
    private func getBatteryInfo() -> BatteryInfo {
        do {
            // Шаг 1: Получаем информацию об источниках питания
            guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
                throw BatteryError.powerSourceUnavailable
            }
            
            // Шаг 2: Получаем список источников
            guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
                  !sources.isEmpty else {
                throw BatteryError.batteryInfoUnavailable("Нет доступных источников питания")
            }
            
            // Шаг 3: Берём первый источник (обычно это батарея)
            let source = sources.first!
            
            // Шаг 4: Получаем описание источника питания
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                throw BatteryError.batteryInfoUnavailable("Не удалось получить описание источника питания")
            }
            
            // Шаг 5: Извлекаем параметры с проверкой ошибок
            guard let currentCapacity = description[kIOPSCurrentCapacityKey] as? Float else {
                throw BatteryError.batteryParameterMissing("Текущая ёмкость")
            }
            
            guard let maxCapacity = description[kIOPSMaxCapacityKey] as? Float else {
                throw BatteryError.batteryParameterMissing("Максимальная ёмкость")
            }
            
            guard let powerSource = description[kIOPSPowerSourceStateKey] as? String else {
                throw BatteryError.batteryParameterMissing("Источник питания")
            }
            
            // Шаг 6: Создаём структуру с обязательными параметрами
            let batteryInfo = BatteryInfo(
                isCharging: powerSource == kIOPSACPowerValue,
                currentCapacity: currentCapacity,
                maxCapacity: maxCapacity,
            )
            
            
            return batteryInfo
            
        } catch BatteryError.powerSourceUnavailable {
            print("⚠️ Ошибка: Источник питания недоступен")
            return defaultBatteryInfo
        } catch BatteryError.batteryInfoUnavailable(let reason) {
            print("⚠️ Ошибка: Информация о батарее недоступна - \(reason)")
            return defaultBatteryInfo
        } catch BatteryError.batteryParameterMissing(let parameter) {
            print("⚠️ Ошибка: Отсутствует параметр батареи - \(parameter)")
            return defaultBatteryInfo
        } catch {
            print("⚠️ Ошибка: Неожиданная ошибка - \(error.localizedDescription)")
            return defaultBatteryInfo
        }
    }
    
    // MARK: - Управление наблюдателями (Observer Pattern)
    
    /// Добавляет наблюдателя для отслеживания событий батареи
    /// - Parameter observer: Замыкание, которое будет вызываться при событиях
    /// - Returns: ID наблюдателя для последующего удаления
    func addObserver(_ observer: @escaping (BatteryEvent) -> Void) -> Int {
        observers.append(observer)
        return observers.count - 1
    }
    
    /// Удаляет наблюдателя по его ID
    /// - Parameter id: ID наблюдателя
    func removeObserver(byId id: Int) {
        guard id >= 0 && id < observers.count else { return }
        observers.remove(at: id)
    }
    
    /// Уведомляет всех наблюдателей о событии
    /// - Parameter event: Событие батареи
    private func notifyObservers(of event: BatteryEvent) {
        for observer in observers {
            observer(event)
        }
    }
    
    // MARK: - Очередь уведомлений (для предотвращения спама)
    
    /// Добавляет уведомление в очередь
    /// - Parameter event: Событие для добавления
    private func queueNotification(_ event: BatteryEvent) {
        notificationQueue.append(event)
        processNotificationQueue()
    }
    
    /// Обрабатывает очередь уведомлений
    private func processNotificationQueue() {
        // Если уже обрабатываем - выходим
        guard !isProcessingNotifications else { return }
        
        isProcessingNotifications = true
        
        // Обрабатываем все уведомления в очереди
        while !notificationQueue.isEmpty {
            let event = notificationQueue.removeFirst()
            notifyObservers(of: event)
        }
        
        isProcessingNotifications = false
    }

    
    // MARK: - Cleanup
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}
