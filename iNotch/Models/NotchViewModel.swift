//
//  NotchViewModel.swift
//  iNotch
//
//  Created by Petru Orbu on 18.11.2025.
//

import Defaults
import SwiftUI
import Combine

class NotchViewModel: ObservableObject {
    let animationLibrary: NotchAnimations = .init()
    let animation: Animation
    
    // @Published - при изменении UI обновится автоматически
    // private(set) - читать можно везде, менять только внутри класса
    @Published private(set) var notchState: NotchState = .closed
    
    // Текущий размер вырезки (меняется при анимации)
    @Published var notchSize: CGSize = getClosedNotchSize()
    
    @Published var hideOnClosed: Bool = true
    
    // Текущий размер вырезки (меняется при анимации)
    @Published var closedNotchSize: CGSize = getClosedNotchSize()
    
    /// Прогресс жеста (для визуальной обратной связи)
    @Published var gestureProgress: CGFloat = .zero
    
    /// Флаг для календаря (чтобы не закрывать при свайпе в календаре)
    @Published var isHoveringCalendar: Bool = false
    
    // Имя экрана (опционально)
    @Published var screen: String?
    
    init(screen: String? = nil){
        // Получаем анимацию
        animation = animationLibrary.animation
        
        // Сохраняем экран
        self.screen = screen
        
        // Вычисляем размеры
        notchSize = getClosedNotchSize(screen: screen)
        closedNotchSize = notchSize
    }
    
    var effectiveClosedNotchHeight: CGFloat {
           let currentScreen = NSScreen.screens.first { $0.localizedName == screen }
           let noNotchAndFullscreen = hideOnClosed && (currentScreen?.safeAreaInsets.top ?? 0 <= 0 || currentScreen == nil)
           return noNotchAndFullscreen ? 0 : closedNotchSize.height
       }
    
    /// Открывает Notch с анимацией
    func open(){
        withAnimation(.bouncy) {
            self.notchSize = openNotchSize
            self.notchState = .open
        }
    }
    
    /// Закрывает вырезку с анимацией
    func close(){
        withAnimation(.smooth){
            self.notchSize = getClosedNotchSize(screen: self.screen)
            self.closedNotchSize = self.notchSize
            self.notchState = .closed
        }
    }
        
    /// Переключает состояние (открыто ↔ закрыто)
    func toggle() {
        if notchState == .closed {
            open()
        } else {
            close()
        }
    }
}

