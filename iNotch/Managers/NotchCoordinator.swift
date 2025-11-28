
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
			print("📨 NotchCoordinator: Received device connection event")
			
			guard Defaults[.enableDeviceConnectionSneakPeek] else {
				print("   ⚠️ Device connection notifications are disabled")
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
				return
			}
			
			switch event {
			case .connected(let deviceInfo):
				print("   └─ Event type: .connected")
				print("   └─ Device: \(deviceInfo.name)")
				print("   └─ ID: \(deviceInfo.deviceID)")
				print("   └─ Battery: \(deviceInfo.batteryLevel?.description ?? "N/A")%")
				self?.handleDeviceConnected(deviceInfo)
			case .disconnected(let deviceInfo):
				print("   └─ Event type: .disconnected")
				print("   └─ Device: \(deviceInfo.name)")
				print("   └─ ID: \(deviceInfo.deviceID)")
				// Handle disconnection if needed
				break
			case .moved(let deviceInfo, let toDevice):
				print("   └─ Event type: .moved")
				print("   └─ Device: \(deviceInfo.name)")
				print("   └─ ID: \(deviceInfo.deviceID)")
				print("   └─ Moved to: \(toDevice ?? "Unknown")")
				self?.handleDeviceMoved(deviceInfo, toDevice: toDevice)
			case .batteryUpdated(let deviceInfo):
				print("   └─ Event type: .batteryUpdated")
				print("   └─ Device: \(deviceInfo.name)")
				print("   └─ Battery: \(deviceInfo.batteryLevel?.description ?? "N/A")%")
				// Optionally show battery update
				break
			}
			print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
		}
		.store(in: &cancellables)
	print("✅ NotchCoordinator: Device connection observer setup complete")
}

private func handleDeviceConnected(_ deviceInfo: DeviceInfo) {
	print("🎯 NotchCoordinator: Handling device connected...")
	print("   └─ Device: \(deviceInfo.name)")
	print("   └─ Battery: \(deviceInfo.batteryLevel?.description ?? "N/A")%")
    
    print(deviceInfo)
	
	let duration = Defaults[.deviceConnectionHUDDuration]
	
	let icon = getDeviceIcon(for: deviceInfo.name)
	print("   └─ Icon: \(icon)")
	
	print("   └─ Calling showSneakPeek...")
    
	showSneakPeek(
		type: .deviceConnection,
		value: deviceInfo.batteryLevel ?? 0,
		icon: icon,
        title: deviceInfo.isBluetooth ? "Connected" : "Disconnected",
		duration: duration,
//			deviceName: deviceInfo.name,
//			deviceBattery: deviceInfo.batteryLevel,
//			canReconnect: false
	)
	print("✅ NotchCoordinator: Device connected handler complete")
}

private func handleDeviceMoved(_ deviceInfo: DeviceInfo, toDevice: String?) {
	print("🎯 NotchCoordinator: Handling device moved...")
	print("   └─ Device: \(deviceInfo.name)")
	print("   └─ Battery: \(deviceInfo.batteryLevel?.description ?? "N/A")%")
	print("   └─ Moved to: \(toDevice ?? "Unknown")")
	
	let duration = Defaults[.deviceConnectionHUDDuration]
	print("   └─ Duration: \(duration)s")
	
	let icon = getDeviceIcon(for: deviceInfo.name)
	print("   └─ Icon: \(icon)")
	
	let title = "Moved to \(toDevice ?? "Other Device")"
	print("   └─ Title: \(title)")
	
	print("   └─ Calling showSneakPeek...")
	showSneakPeek(
		type: .deviceConnection,
		value: deviceInfo.batteryLevel ?? 0,
		icon: icon,
		title: title,
		titleColor: .gray,
		iconColor: .white,
		valueColor: .gray,
		duration: duration,
//			deviceName: deviceInfo.name,
//			deviceBattery: deviceInfo.batteryLevel,
//			canReconnect: true,
//			movedToDevice: toDevice
	)
	print("✅ NotchCoordinator: Device moved handler complete")
}

    private func getDeviceIcon(for deviceName: String) -> String {
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
            icon = "macbook.gen2"
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
