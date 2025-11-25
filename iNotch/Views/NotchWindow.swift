//
//  NotchWindow.swift
//  iNotch
//
// Кастомное окно, которое плавает поверх всех других окон
//
//  Created by Petru Orbu on 18.11.2025.
//


import Cocoa

class NotchWindow: NSPanel {
    /// Переопределяем инициализатор для настройки окна
    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ){
        // Вызываем родительский инициализатор
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: flag)
        
        // НАСТРОЙКИ ОКНА
        // Плавающая панель (всегда сверху)
        isFloatingPanel = true
        
        // Может быть прозрачным
        isOpaque = false
        
        // Скрываем заголовок
        titleVisibility = .hidden
        
        // Прозрачная панель заголовка
        titlebarAppearsTransparent = true
        
        // Прозрачный фон
        backgroundColor = .clear
        
        // Нельзя перетаскивать
        isMovable = false
        
        // Поведение в системе
        collectionBehavior = [
            .fullScreenAuxiliary, // Показывать в полноэкранном режиме
            .stationary,          // Не двигается
            .canJoinAllSpaces,    // На всех рабочих столах
            .ignoresCycle         // Не появляется в Cmd+Tab
        ]
        
        // Не закрывается автоматически
        isReleasedWhenClosed = false
        
        // Очень высокий приоритет (поверх меню)
        level = .mainMenu + 3
        
        // Без тени
        hasShadow = false
    }
    
    // Не может стать активным (не перехватывает клавиатуру)
    override var canBecomeKey: Bool{
        false
    }
    
    // Не может стать главным
    override var canBecomeMain: Bool{
        false
    }
}
