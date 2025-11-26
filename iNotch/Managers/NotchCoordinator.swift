
//
//  NotchCoordinator.swift
//  iNotch
//
//  Координатор для управления Sneak Peek уведомлениями
//  Архитектура boring.notch адаптированная для iNotch
//
//  Ответственность:
//  - Управление состоянием Sneak Peek
//  - Автоматическое скрытие через таймер
//  - Координация между батареей и UI
//

import Combine
import Defaults
import SwiftUI

/// Структура Sneak Peek состояния
struct SneakPeekState {
    var show: Bool = false
    var type: SneakContentType = .battery
    var value: Int = 0
    var icon: String = ""
    var title: String = ""
    
    var titleColor: Color = .white
    var valueColor: Color = .white
    var iconColor: Color = .white
}

/// Координатор для управления Sneak Peek уведомлениями
class NotchCoordinator: ObservableObject {
    // Singleton
    static let shared = NotchCoordinator()
    
    
    /// Текущее состояние Sneak Peek
    @Published var sneakPeek: SneakPeekState = .init() {
        didSet {
            if sneakPeek.show {
                // Запускаем таймер автоскрытия
                scheduleSneakPeekHide(after: sneakPeekDuration)
            } else {
                // Отменяем таймер
                sneakPeekTask?.cancel()
            }
        }
    }
    
    
    /// Продолжительность показа Sneak Peek (в секундах)
    private var sneakPeekDuration: TimeInterval = 3.0
    /// Задача автоскрытия
    private var sneakPeekTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    
    private init() {
        // Подписываемся на события батареи
        setupBatteryObserver()
        setupMusicObserver()
        setupVolumeObserver()
    }
    
    
    /// Настраивает observer для событий батареи
    private func setupBatteryObserver() {
        let batteryViewModel = BatteryStatusViewModel.shared
        
        // Подписываемся на публикуемые изменения
        batteryViewModel.$isCharging
            .dropFirst() // Пропускаем начальное значение
            .sink { [weak self] isPluggedIn in
                self?.handlePowerSourceChanged(isCharging: isPluggedIn)
            }
            .store(in: &cancellables)
        
        batteryViewModel.$levelBattery
            .dropFirst()
            .sink { [weak self] level in
                self?.handleBatteryLevelChanged(level: level)
            }
            .store(in: &cancellables)
    }
    
    private func setupVolumeObserver(){
        let volumeManager = VolumeManager.shared
        
        volumeManager.volumeChanged
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] volume in
            self?.handleVolumeChanged(volume: volume)
        }
        .store(in: &cancellables)
        
    }
    
    private func setupMusicObserver() {
        let musicManager = MusicManager.shared
        
        musicManager.$trackChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                let title = musicManager.songTitle
                let artist = musicManager.artistName
                
                if !title.isEmpty && title != "No Track Playing" {
                    self?.handleMusicTrackChanged(title: title, artist: artist)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Обрабатывает изменение источника питания
    private func handlePowerSourceChanged(isCharging: Bool) {
        let battery = BatteryStatusViewModel.shared
        
        var percentage: Int = 100
        
        switch Int(battery.levelBattery) {
            case 0...7: percentage = 0
            case 8...35: percentage = 25
            case 36...64: percentage = 50
            case 65...95: percentage = 75
            default: percentage = 100
        }
        
        showSneakPeek(
            type: .battery,
            value: Int(battery.levelBattery),
            icon: "battery.\(percentage)percent",
            title: isCharging ? "Charging" : "Unplugged",
            iconColor: isCharging ? .green : .white,
            valueColor: isCharging ? .green : .white,
            duration: 4.0
        )

    }
    
    private func handleVolumeChanged(volume: Float) {
		guard Defaults[.enableVolumeSneakPeek] else { return }

        let volumeManager = VolumeManager.shared
		let duration = Defaults[.volumeHUDDuration]

		let icon: String

		switch Defaults[.volumeIconMode] {
			case .speakers:
				icon = volumeManager.speakerIcon(for: volume)
			case .outputDevice:
				icon = volumeManager.getDeviceIcon() ?? volumeManager.speakerIcon(for: volume)
		}
			
        
        showSneakPeek(
            type: .volume,
            value: Int(volume * 100),
            icon: icon,
            title: volumeManager.isMuted || (volume * 100) == 0 ? "Silent" : "",
            iconColor: (volume * 100) == 0 || volumeManager.isMuted ? .red : .white,
            valueColor: (volume * 100) == 0 || volumeManager.isMuted ? .red : .white,
			duration: duration
        )
    }
    
    /// Обрабатывает изменение уровня заряда
    private func handleBatteryLevelChanged(level: Float) {
        let battery = BatteryStatusViewModel.shared
        
        // Показываем только для низкого заряда (<10%) когда не заряжается
        if level <= 10 && !battery.isCharging {
            showSneakPeek(
                type: .battery,
                value: Int(level),
                icon: "battery.25",
                title: "Battery Low",
                iconColor: .red,
                valueColor: .red,
                duration: 4.0
            )
        }
        
        // Показываем для полной зарядки
        if Int(level) == 100 && battery.isCharging {
            showSneakPeek(
                type: .battery,
                value: 100,
                icon: "battery.100",
                title: "Battery Full",
                iconColor: .green,
                valueColor: .green,
                duration: 4.0
            )
        }
    }
    
    
    private func handleMusicTrackChanged(title: String, artist: String) {        
        withAnimation(.smooth) {
            sneakPeek = SneakPeekState(
                show: true,
                type: .music,
                value: 0,
                icon: "music.note",
                title: "\(title) - \(artist)",
                titleColor: .white,
                valueColor: .white,
                iconColor: .white
            )
        }
    }
    
    
    // MARK: - Управление Sneak Peek
    
    func showSneakPeek(
        type: SneakContentType,
        value: Int,
        icon: String,
        title: String,
        titleColor: Color = .white,
        iconColor: Color = .white,
        valueColor: Color = .white,
        duration: TimeInterval = 3.0
    ) {
        sneakPeekDuration = duration

		let animationSpeed: TimeInterval

		if type == .volume {
			animationSpeed = Defaults[.volumeAnimationSpeed].animationDuration
		} else {
			animationSpeed = 0.3
		}	
        
        DispatchQueue.main.async {
            withAnimation(.smooth(duration: animationSpeed)) {
                self.sneakPeek = SneakPeekState(
                    show: true,
                    type: type,
                    value: value,
                    icon: icon,
                    title: title,
                    titleColor: titleColor,
                    valueColor: valueColor,
                    iconColor: iconColor
                )
            }
        }
    }
    
    func hideSneakPeek() {
        DispatchQueue.main.async {
            withAnimation(.smooth(duration: 0.3)) {
                self.sneakPeek.show = false
            }
        }
    }
    
    /// Планирует автоматическое скрытие через указанное время
    private func scheduleSneakPeekHide(after duration: TimeInterval) {
        sneakPeekTask?.cancel()
        
        sneakPeekTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self = self, !Task.isCancelled else { return }
            
            await MainActor.run {
                self.hideSneakPeek()
            }
        }
    }
}
