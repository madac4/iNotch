//
//  NotchSizing.swift
//  iNotch
//
//  Отвечает за вычисление размеров вырезки для разных экранов
//  Важно: размеры адаптируются к наличию или отсутствию физической вырезки
//
//  Created by Petru Orbu on 18.11.2025.
//

import Defaults
import SwiftUI

// MARK: - Константы размеров

// Размер вырезки в открытом состоянии (фиксированный)
// Ширина: 640 пикселей, высота: 190 пикселей
let batterySneakSize: CGSize = .init(width: 160, height: 1)
let openNotchSize: CGSize = .init(width: 640, height: 190)

// Радиусы скругления углов для разных состояний
// opened: когда вырезка открыта (большие скругления)
// closed: когда вырезка закрыта (меньшие скругления)
// top: верхние углы, bottom: нижние углы
let cornerRadiusInsets: (opened: (top: CGFloat, bottom: CGFloat), closed: (top: CGFloat, bottom: CGFloat)) = (opened: (top: 20, bottom: 24), closed: (top: 6, bottom: 14))


// MARK: - Функции расчёта размеров
/// Вычисляет размер закрытой вырезки в зависимости от экрана
/// - Parameter screen: Имя экрана (опционально). Если nil, используется главный экран

func getClosedNotchSize(screen: String? = nil) -> CGSize{
    var notchHeight: CGFloat = Defaults[.nonNotchHeight]
    var notchWidth: CGFloat = 985
    
    // Определяем экран для работы
    var selectedScreen = NSScreen.main
    
    if let customScreen = screen {
        selectedScreen = NSScreen.screens.first(where: {$0.localizedName == customScreen})
    }
    
   
    // Если экран найден, вычисляем точные размеры
    if let screen = selectedScreen {
        // ВЫЧИСЛЕНИЕ ШИРИНЫ
        // auxiliaryTopLeftArea и auxiliaryTopRightArea - области слева и справа от вырезки
        if let topLeftPadding: CGFloat = screen.auxiliaryTopLeftArea?.width,
           let topRightPadding: CGFloat = screen.auxiliaryTopRightArea?.width {
            notchWidth = screen.frame.width - topLeftPadding - topRightPadding - 16
        }
        
        // ВЫЧИСЛЕНИЕ ВЫСОТЫ (с учётом настроек пользователя)
        // Проверяем наличие физической вырезки
        if screen.safeAreaInsets.top > 0 {
            // ═══ ЭКРАН С ФИЗИЧЕСКОЙ ВЫРЕЗКОЙ ═══
                        
            // Получаем режим высоты из настроек
            notchHeight = Defaults[.notchHeight]
            
            // Применяем режим в зависимости от настроек
            if Defaults[.notchHeightMode] == .matchRealNotchSize {
                // Режим 1: Точная высота физической вырезки
                notchHeight = screen.safeAreaInsets.top
            }else if Defaults[.notchHeightMode] == .matchMenuBar {
                // Режим 2: Высота menu bar (обычно чуть больше вырезки)
                notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
            }
            
            // Режим 3: .custom - используется значение из Defaults[.notchHeight]

        }else {
            // ═══ ЭКРАН БЕЗ ФИЗИЧЕСКОЙ ВЫРЕЗКИ ═══
                        
            // Получаем высоту из настроек для экранов без вырезки
            notchHeight = Defaults[.nonNotchHeight]
            
            // Применяем режим
            if Defaults[.nonNotchHeightMode] == .matchMenuBar {
                notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
            }
        }
    }
    
    return .init(width: notchWidth, height: notchHeight)
}


/// Получает координаты и размеры экрана
/// - Parameter screen: Имя экрана (опционально)
/// - Returns: CGRect с координатами экрана или nil
func getScreenFrame(_ screen: String? = nil) -> CGRect? {
    var selectedScreen = NSScreen.main
    
    if let customScreen = screen {
        selectedScreen = NSScreen.screens.first(where: {$0.localizedName == customScreen})!
    }
    
    return selectedScreen?.frame
}
