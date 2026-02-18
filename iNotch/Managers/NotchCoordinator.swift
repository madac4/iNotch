
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
    static let shared = NotchCoordinator()
    
    
    @Published var sneakPeek: SneakPeekState = .init() {
        didSet {
            if sneakPeek.show {
                scheduleSneakPeekHide(after: sneakPeekDuration)
            } else {
                sneakPeekTask?.cancel()
            }
        }
    }
    
    private var sneakPeekDuration: TimeInterval = 3.0
    private var sneakPeekTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    
    private init() {
        setupBatteryObserver()
        setupMusicObserver()
        setupVolumeObserver()
        setupDeviceConnectionObserver()
    }
    
    private func setupDeviceConnectionObserver() {
        let deviceManager = ConnectivityManager.shared
        
        deviceManager.connectionEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard Defaults[.enableConnectivitySneakPeek] else {return}

                switch event {
                case .connected(let deviceInfo):
                    self?.handleDeviceConnection(deviceInfo)
                case .disconnected(let deviceInfo):
                    if Defaults[.showDisconnectNotification] {
                        self?.handleDeviceConnection(deviceInfo)
                    }
                    break
                case .batteryUpdated(let deviceInfo):
                    self?.handleDeviceBatteryUpdated(deviceInfo)
                }
            }
            .store(in: &cancellables)
    }

    private func handleDeviceConnection(_ deviceInfo: DeviceInfo) {
        let duration = Defaults[.connectivityHUDDuration]
        let icon = getDeviceIcon(for: deviceInfo.name)

		let macBattery = BatteryStatusViewModel.shared.levelBattery
		let deviceBattery = deviceInfo.batteryLevel
	
        if deviceInfo.isBluetooth && deviceBattery == nil {return}
	
        if Defaults[.warnOnLowDeviceBattery], let deviceBattery = deviceBattery, deviceBattery <= Defaults[.lowDeviceBatteryThreshold] {
            handleDeviceLowBattery(deviceInfo)
        } else {
            showSneakPeek(
                type: .deviceConnection,
                value: deviceInfo.isBluetooth ? deviceBattery ?? 0 : Int(macBattery),
                icon: icon,
                title: "",
                duration: duration
            )
        }
    }

    private func handleDeviceLowBattery(_ deviceInfo: DeviceInfo) {
        if Defaults[.playSoundOnLowDeviceBattery] {
            playLowBatterySound()
        }

        let duration = Defaults[.connectivityHUDDuration]
        let icon = getDeviceIcon(for: deviceInfo.name, isBluetooth: deviceInfo.isBluetooth)
            
        showSneakPeek(
            type: .deviceConnection,
            value: deviceInfo.batteryLevel!,
            icon: icon,
            title: "Low Battery",
            titleColor: .red,
            iconColor: .red,
            valueColor: .red,
            duration: duration
        )
    }

	private func handleDeviceBatteryUpdated(_ deviceInfo: DeviceInfo) {
		guard let batteryLevel = deviceInfo.batteryLevel else { return }
		
		let duration = Defaults[.connectivityHUDDuration]
		let icon = getDeviceIcon(for: deviceInfo.name, isBluetooth: deviceInfo.isBluetooth)
		
		// Check if battery is low
		if Defaults[.warnOnLowDeviceBattery], batteryLevel <= Defaults[.lowDeviceBatteryThreshold] {
			handleDeviceLowBattery(deviceInfo)
		} else {
			// Update sneak peek with new battery level (normal connection state)
			showSneakPeek(
				type: .deviceConnection,
				value: batteryLevel,
				icon: icon,
				title: "",
				duration: duration
			)
		}
    }


    private func getDeviceIcon(for deviceName: String, isBluetooth: Bool = false) -> String {
        let lowercased = deviceName.lowercased()
        let icon: String
            
        if lowercased.contains("airpods pro") {
            icon = "airpodspro"
        } else if lowercased.contains("airpods max") {
            icon = "airpodsmax"
        } else if lowercased.contains("airpods") {
            icon = "airpods"
        } else if lowercased.contains("headphone") {
            icon = "headphones"
        } else if lowercased.contains("earbud") {
            icon = "earbuds"
        } else if lowercased.contains("macbook") {
            icon = "macbook"
        } else {
            icon = "headphones"
        }
        
        return icon
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
		guard Defaults[.enableBatterySneakPeek] else { return }

        let battery = BatteryStatusViewModel.shared
		let duration = Defaults[.batteryHUDDuration]
        
        var percentage: Int = 100

        switch Int(battery.levelBattery) {
            case 0...7: percentage = 0
            case 8...35: percentage = 25
            case 36...64: percentage = 50
            case 65...95: percentage = 75
            default: percentage = 100
        }

		if !isCharging && Defaults[.playSoundOnUnplugged] {
			playUnpluggedSound()
		}
        
		if isCharging || (Defaults[.showUnpluggedNotification] && !isCharging) {
			showSneakPeek(
				type: .battery,
				value: Int(battery.levelBattery),
				icon: "battery.\(percentage)percent",
				title: isCharging ? "Charging" : "Unplugged",
				iconColor: isCharging ? .green : .white,
				valueColor: isCharging ? .green : .white,
				duration: duration
			)
		}
    }
    
    private func handleVolumeChanged(volume: Float) {
		guard Defaults[.enableVolumeSneakPeek] else { return }

        let volumeManager = VolumeManager.shared
        let deviceManager = ConnectivityManager.shared
		let duration = Defaults[.volumeHUDDuration]

		let icon: String

		switch Defaults[.volumeIconMode] {
			case .speakers:
				icon = volumeManager.speakerIcon(for: volume)
			case .outputDevice:
                if let deviceName = deviceManager.currentDevice?.name,
                   deviceName.lowercased().contains("macbook") {
                    icon = volumeManager.speakerIcon(for: volume)
                } else if let deviceName = deviceManager.currentDevice?.name {
                    icon = getDeviceIcon(for: deviceName)
                } else {
                    icon = volumeManager.speakerIcon(for: volume)
                }
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
		guard Defaults[.enableBatterySneakPeek] else { return }

        let battery = BatteryStatusViewModel.shared
		let threshold = Defaults[.lowBatteryThreshold]
		let duration = Defaults[.batteryHUDDuration]
        
        if level <= Float(threshold) && !battery.isCharging && Defaults[.warnOnLowBattery] {
			if Defaults[.playSoundOnLowBattery] {
				playLowBatterySound()
			}

            showSneakPeek(
                type: .battery,
                value: Int(level),
                icon: "battery.25",
                title: "Battery Low",
                iconColor: .red,
                valueColor: .red,
                duration: duration
            )
        }
        
        if Int(level) == 100 && battery.isCharging {
            showSneakPeek(
                type: .battery,
                value: 100,
                icon: "battery.100",
                title: "Battery Full",
                iconColor: .green,
                valueColor: .green,
                duration: duration
            )
        }
    }

	private func playLowBatterySound() {
        DispatchQueue.main.async {
            if let sound = NSSound(named: "Bottle") {
                sound.play()
            }
        }
    }

	private func playUnpluggedSound() {
        DispatchQueue.main.async {
            if let sound = NSSound(named: "Funk") {
                sound.play()
            }
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
			animationSpeed = Defaults[.animationSpeed].animationDuration
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
