//
//  CGSSpace.swift
//  iNotch
//
//  Обёртка над приватным API от Apple для управления "пространствами" окон
//  Оригинальный источник: https://github.com/avaidyam/Parrot/
//  Используется в boring.notch
//
//  ⚠️ ВНИМАНИЕ: Использует приватный API!
//  Apple может отклонить приложение в App Store при его использовании
//

import AppKit

/// Класс для управления специальным "пространством" окон на максимальном уровне
/// Позволяет окнам быть поверх ВСЕХ других элементов системы
public final class CGSSpace {
    // Идентификатор пространства
    private let identifier: CGSSpaceID
    
    // Флаг: создано ли пространство через init
    private let createdByInit: Bool
    
    /// Набор окон в этом пространстве
    /// При изменении автоматически добавляет/удаляет окна из пространства
    public var windows: Set<NSWindow> = [] {
        didSet {
            // Находим окна для удаления (были, но больше нет)
            let remove = oldValue.subtracting(self.windows)
            // Находим окна для добавления (новые)
            let add = self.windows.subtracting(oldValue)
            
            // Удаляем старые окна из пространства
            CGSRemoveWindowsFromSpaces(
                _CGSDefaultConnection(),
                remove.map { $0.windowNumber } as NSArray,
                [self.identifier] as NSArray
            )
            
            // Добавляем новые окна в пространство
            CGSAddWindowsToSpaces(
                _CGSDefaultConnection(),
                add.map { $0.windowNumber } as NSArray,
                [self.identifier] as NSArray
            )
        }
    }
    
    /// Создаёт новое пространство с указанным уровнем
    /// ⚠️ ВАЖНО: Пространство ДОЛЖНО быть уничтожено при выходе из приложения!
    /// - Parameter level: Уровень пространства (2147483647 = максимальный)
    public init(level: Int = 0) {
        // Флаг ДОЛЖЕН быть 1, иначе Finder будет рисовать иконки рабочего стола
        let flag = 0x1
        
        // Создаём пространство
        self.identifier = CGSSpaceCreate(_CGSDefaultConnection(), flag, nil)
        
        // Устанавливаем абсолютный уровень
        CGSSpaceSetAbsoluteLevel(_CGSDefaultConnection(), self.identifier, level)
        
        // Показываем пространство
        CGSShowSpaces(_CGSDefaultConnection(), [self.identifier] as NSArray)
        
        // Отмечаем что создано через init
        self.createdByInit = true
    }
    
    /// Создаёт обёртку для существующего пространства
    /// - Parameter id: ID существующего пространства
    public init(id: UInt64) {
        self.identifier = id
        CGSShowSpaces(_CGSDefaultConnection(), [self.identifier] as NSArray)
        self.createdByInit = false
    }
    
    /// Деструктор - скрывает и уничтожает пространство
    deinit {
        // Скрываем пространство
        CGSHideSpaces(_CGSDefaultConnection(), [self.identifier] as NSArray)
        
        // Уничтожаем только если создано через init
        if createdByInit {
            CGSSpaceDestroy(_CGSDefaultConnection(), self.identifier)
        }
    }
}

// MARK: - Приватный API от Apple

/// Типы данных для CGS API
fileprivate typealias CGSConnectionID = UInt
fileprivate typealias CGSSpaceID = UInt64

/// @_silgen_name - связывает Swift функцию с C функцией из приватного фреймворка
/// Эти функции существуют в SkyLight.framework (приватный фреймворк macOS)

/// Получает соединение по умолчанию с оконным сервером
@_silgen_name("_CGSDefaultConnection")
fileprivate func _CGSDefaultConnection() -> CGSConnectionID

/// Создаёт новое пространство
@_silgen_name("CGSSpaceCreate")
fileprivate func CGSSpaceCreate(_ cid: CGSConnectionID, _ unknown: Int, _ options: NSDictionary?) -> CGSSpaceID

/// Уничтожает пространство
@_silgen_name("CGSSpaceDestroy")
fileprivate func CGSSpaceDestroy(_ cid: CGSConnectionID, _ space: CGSSpaceID)

/// Устанавливает абсолютный уровень пространства
@_silgen_name("CGSSpaceSetAbsoluteLevel")
fileprivate func CGSSpaceSetAbsoluteLevel(_ cid: CGSConnectionID, _ space: CGSSpaceID, _ level: Int)

/// Добавляет окна в пространства
@_silgen_name("CGSAddWindowsToSpaces")
fileprivate func CGSAddWindowsToSpaces(_ cid: CGSConnectionID, _ windows: NSArray, _ spaces: NSArray)

/// Удаляет окна из пространств
@_silgen_name("CGSRemoveWindowsFromSpaces")
fileprivate func CGSRemoveWindowsFromSpaces(_ cid: CGSConnectionID, _ windows: NSArray, _ spaces: NSArray)

/// Скрывает пространства
@_silgen_name("CGSHideSpaces")
fileprivate func CGSHideSpaces(_ cid: CGSConnectionID, _ spaces: NSArray)

/// Показывает пространства
@_silgen_name("CGSShowSpaces")
fileprivate func CGSShowSpaces(_ cid: CGSConnectionID, _ spaces: NSArray)
