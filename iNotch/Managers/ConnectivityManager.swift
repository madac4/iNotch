import Foundation
import CoreAudio
import IOBluetooth
import Combine
import SwiftUI
import IOKit
import IOKit.hid
import CoreBluetooth

// Bluetooth transport type constant ('blue' = 0x626C7565)
private let kAudioDeviceTransportTypeBluetooth: UInt32 = 0x626C7565

struct DeviceInfo {
	let deviceID: AudioDeviceID
	let name: String
	let isBluetooth: Bool
	let batteryLevel: Int?
	let bluetoothAddress: String?
}

enum ConnectivityEvent {
	case connected(DeviceInfo)
	case disconnected(DeviceInfo)
	case batteryUpdated(DeviceInfo)
}

class ConnectivityManager: NSObject, ObservableObject {
	static let shared = ConnectivityManager()

    @Published var connectionEvent = PassthroughSubject<ConnectivityEvent, Never>()
	@Published var currentDevice: DeviceInfo?

	private var deviceChangeCallback: AudioObjectPropertyListenerProc?
	private var cancellables = Set<AnyCancellable>()
	private var previousDeviceID: AudioDeviceID = 0

	private var centralManager: CBCentralManager?
	private var discoveredPeripherals: [CBPeripheral] = []
	private var batteryReadCompletion: ((Int?) -> Void)?
	private var targetDeviceName: String?
	private var bluetoothReadySemaphore: DispatchSemaphore?
	private var lastBatteryReadTime: [String: Date] = [:]
	private var cachedBatteryLevels: [String: Int] = [:] // Cache battery by device name
	private var isScanning = false

	private override init() {
		super.init()
		setupDeviceMonitoring()
		setupCoreBluetooth()
		checkCurrentDevice()
	}
	
	private func setupCoreBluetooth() {
		centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "com.inotch.bluetooth.battery"))
	}

    private func setupDeviceMonitoring() {
        let callback: AudioObjectPropertyListenerProc = { (
            inObjectID: AudioObjectID,
            inNumberAddresses: UInt32,
            inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
            inClientData: UnsafeMutableRawPointer?
        ) -> OSStatus in
            guard let managerPointer = inClientData?.assumingMemoryBound(to: ConnectivityManager.self) else {
                return noErr
            }
            
            let manager = managerPointer.pointee
            
            DispatchQueue.main.async {
                manager.handleDeviceChange()
            }
            
            return noErr
        }
        
        self.deviceChangeCallback = callback
        
        let selfPointer = UnsafeMutablePointer<ConnectivityManager>.allocate(capacity: 1)
        selfPointer.initialize(to: self)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            callback,
            selfPointer
        )
        
        if status != noErr {
            print("⚠️ DeviceConnectionManager: Failed to add device change listener, status: \(status)")
        }
    }

	private func handleDeviceChange() {
        let oldDevice = currentDevice
        checkCurrentDevice()
        let newDevice = currentDevice

        // 1. Disconnect old device if needed
        if let old = oldDevice, old.isBluetooth {
            let isStillConnected = newDevice?.deviceID == old.deviceID && (newDevice?.isBluetooth ?? false)
            if !isStillConnected {
                connectionEvent.send(.disconnected(old))
            }
        }

        // 2. Connect new device if needed
        if let new = newDevice {
            let wasAlreadyConnected = oldDevice?.deviceID == new.deviceID && (oldDevice?.isBluetooth == new.isBluetooth)
            if !wasAlreadyConnected {
                connectionEvent.send(.connected(new))
            }
        }
	}

	private func checkCurrentDevice() {
        let newDeviceID = getDefaultOutputDevice()
        
        guard newDeviceID != 0 else {
            previousDeviceID = currentDevice?.deviceID ?? 0
            currentDevice = nil
            return
        }
        
        if newDeviceID != previousDeviceID {
            previousDeviceID = newDeviceID
            
            if let deviceInfo = getDeviceInfo(deviceID: newDeviceID) {
                currentDevice = deviceInfo
            } else {
                currentDevice = nil
            }
        } else {
            // Same device, update info if needed
            if let updatedInfo = getDeviceInfo(deviceID: newDeviceID) {
                currentDevice = updatedInfo
            }
        }
    }
	
    private func getDefaultOutputDevice() -> AudioDeviceID {
        var deviceID: AudioDeviceID = 0
        var deviceIDSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &deviceIDSize,
            &deviceID
        )
        
        if status != noErr {
            return 0
        }
        
        return deviceID
    }
    
    private func getDeviceInfo(deviceID: AudioDeviceID) -> DeviceInfo? {
        guard let deviceName = getDeviceName(deviceID: deviceID) else {
            return nil
        }
        
        let isBluetooth = isBluetoothDevice(deviceID: deviceID)
        
        // Use cached battery if available (within last 5 minutes)
        var batteryLevel: Int? = nil
        if isBluetooth, let cachedBattery = cachedBatteryLevels[deviceName] {
            if let lastRead = lastBatteryReadTime[deviceName],
               Date().timeIntervalSince(lastRead) < 300 { // 5 minutes cache
                batteryLevel = cachedBattery
            }
        }
        
        // Return device info immediately with cached battery if available
        let deviceInfo = DeviceInfo(
            deviceID: deviceID,
            name: deviceName,
            isBluetooth: isBluetooth,
            batteryLevel: batteryLevel,
            bluetoothAddress: nil
        )
        
        // Fetch fresh battery and address asynchronously if Bluetooth device
        if isBluetooth {
            fetchBluetoothInfoAsync(deviceName: deviceName, deviceID: deviceID)
        }
        
        return deviceInfo
    }
    
    private func fetchBluetoothInfoAsync(deviceName: String, deviceID: AudioDeviceID) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let batteryLevel = self.getBluetoothBattery(deviceName: deviceName)
            let bluetoothAddress = self.getBluetoothAddress(deviceName: deviceName)
            
            // Cache battery level
            if let battery = batteryLevel {
                self.cachedBatteryLevels[deviceName] = battery
                self.lastBatteryReadTime[deviceName] = Date()
            }
            
            // Update device info on main thread
            DispatchQueue.main.async {
                if let currentDevice = self.currentDevice,
                   currentDevice.deviceID == deviceID {
                    let updatedDevice = DeviceInfo(
                        deviceID: currentDevice.deviceID,
                        name: currentDevice.name,
                        isBluetooth: currentDevice.isBluetooth,
                        batteryLevel: batteryLevel,
                        bluetoothAddress: bluetoothAddress
                    )
                    self.currentDevice = updatedDevice
                    
                    // Send battery update event if battery was retrieved and different from cached
                    if let battery = batteryLevel,
                       currentDevice.batteryLevel != battery {
                        self.connectionEvent.send(.batteryUpdated(updatedDevice))
                    }
                }
            }
        }
    }
    
    private func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr, dataSize == UInt32(MemoryLayout<CFString?>.size) else {
            return nil
        }
        
        var cfName: CFString? = nil
        status = withUnsafeMutablePointer(to: &cfName) { ptr -> OSStatus in
            var localSize = dataSize
            return AudioObjectGetPropertyData(
                deviceID,
                &address,
                0,
                nil,
                &localSize,
                ptr
            )
        }
        
        guard status == noErr, let name = cfName as String? else {
            return nil
        }
        return name
    }
    
    private func isBluetoothDevice(deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var transportType: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            &transportType
        )
        
        guard status == noErr else {
            return false
        }
        
        return transportType == kAudioDeviceTransportTypeBluetooth
    }
    
    func getBluetoothBattery(deviceName: String) -> Int? {
        guard let centralManager = centralManager else {
            return nil
        }
        
        // Wait for Bluetooth to be ready (powered on)
        if centralManager.state != .poweredOn {
            // Create semaphore to wait for state update
            let readySemaphore = DispatchSemaphore(value: 0)
            bluetoothReadySemaphore = readySemaphore
            
            // Wait up to 3 seconds for Bluetooth to become ready
            let waitResult = readySemaphore.wait(timeout: .now() + 3.0)
            bluetoothReadySemaphore = nil
            
            if waitResult == .timedOut || centralManager.state != .poweredOn {
                return nil
            }
        }
        
        // Stop any existing scan to clear cache and get fresh data
        if isScanning {
            centralManager.stopScan()
            isScanning = false
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        // Use semaphore to wait for async CoreBluetooth operations
        let semaphore = DispatchSemaphore(value: 0)
        var batteryResult: Int? = nil
        var batteryReadCount = 0
        var lastBatteryValue: Int? = nil
        let scanStartTime = Date()
        
        targetDeviceName = deviceName
        batteryReadCompletion = { battery in
            if let battery = battery {
                batteryReadCount += 1
                let timeSinceScanStart = Date().timeIntervalSince(scanStartTime)
                lastBatteryValue = battery
                
                // Use first reading immediately if we've waited at least 200ms
                // This makes it much faster while still giving time for advertisement data
                if timeSinceScanStart >= 0.2 && batteryReadCount >= 1 {
                    batteryResult = battery
                    semaphore.signal()
                }
            }
        }
        
        // Clear previous discoveries to avoid stale data
        discoveredPeripherals.removeAll()
        
        // Scan for all peripherals to read advertisement data
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        
        // Wait for result with shorter timeout for faster response
        let timeoutResult = semaphore.wait(timeout: .now() + 1.5)
        
        // Stop scanning
        centralManager.stopScan()
        isScanning = false
        
        // Clean up
        batteryReadCompletion = nil
        targetDeviceName = nil
        
        if timeoutResult == .timedOut {
            if let lastBattery = lastBatteryValue {
                return lastBattery
            }
            return nil
        }
        
        if let battery = batteryResult {
            return battery
        } else if let lastBattery = lastBatteryValue {
            return lastBattery
        }
        
        return nil
    }

/// Helper to get device ID by name
private func getDeviceIDByName(deviceName: String) -> AudioDeviceID? {
	var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
	
	var address = AudioObjectPropertyAddress(
		mSelector: kAudioHardwarePropertyDevices,
		mScope: kAudioObjectPropertyScopeGlobal,
		mElement: kAudioObjectPropertyElementMain
	)
	
	var status = AudioObjectGetPropertyDataSize(
		AudioObjectID(kAudioObjectSystemObject),
		&address,
		0,
		nil,
		&propertySize
	)
	
	guard status == noErr else { return nil }
	
	let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
	var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
	
	status = AudioObjectGetPropertyData(
		AudioObjectID(kAudioObjectSystemObject),
		&address,
		0,
		nil,
		&propertySize,
		&deviceIDs
	)
	
	guard status == noErr else { return nil }
	
	for id in deviceIDs {
		if let name = getDeviceName(deviceID: id), name == deviceName {
			return id
		}
	}
	
	return nil
}
    
    private func getBluetoothAddress(deviceName: String) -> String? {
        do {
            guard let pairedDevices = IOBluetoothDevice.pairedDevices() else {
                return nil
            }
            
            for device in pairedDevices {
                if let btDevice = device as? IOBluetoothDevice {
                    if btDevice.name == deviceName || deviceName.contains(btDevice.name ?? "") {
                        return btDevice.addressString
                    }
                }
            }
        }
        
        return nil
    }
    
    
    deinit {
        if let callback = deviceChangeCallback {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            AudioObjectRemovePropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                callback,
                nil
            )
        }
    }
}

// MARK: - CoreBluetooth Delegate
extension ConnectivityManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Signal semaphore if we're waiting for Bluetooth to be ready
            bluetoothReadySemaphore?.signal()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let targetName = targetDeviceName else { return }
        
        let peripheralName = peripheral.name ?? ""
        
        // Check if this matches our target device by name
        let nameMatches = !peripheralName.isEmpty && (
            peripheralName == targetName ||
            peripheralName.lowercased().contains(targetName.lowercased()) ||
            targetName.lowercased().contains(peripheralName.lowercased()) ||
            (peripheralName.lowercased().contains("airpod") && targetName.lowercased().contains("airpod"))
        )
        
        // Only process if name matches
        if nameMatches {
            // Check for ProximityPairingStatusDecrypted first (this contains battery for AirPods)
            if let proximityData = advertisementData["kCBAdvDataProximityPairingStatusDecrypted"] as? Data {
                // AirPods battery is typically in proximity data
                if proximityData.count >= 3 {
                    let left = Int(proximityData[0])
                    let right = Int(proximityData[1])
                    let caseBattery = Int(proximityData[2])
                    
                    if left >= 0 && left <= 100 && right >= 0 && right <= 100 && caseBattery >= 0 && caseBattery <= 100 {
                        let minBattery = min(left, right)
                        batteryReadCompletion?(minBattery)
                        return
                    }
                }
                
                // Try other positions if first didn't work
                if proximityData.count >= 6 {
                    let left2 = Int(proximityData[3])
                    let right2 = Int(proximityData[4])
                    let case2 = Int(proximityData[5])
                    
                    if left2 >= 0 && left2 <= 100 && right2 >= 0 && right2 <= 100 && case2 >= 0 && case2 <= 100 {
                        let minBattery = min(left2, right2)
                        batteryReadCompletion?(minBattery)
                        return
                    }
                }
            }
            
            // Check for manufacturer data
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
               manufacturerData.count >= 1,
               manufacturerData[0] == 0x4C { // Apple manufacturer ID
                
                // ALWAYS prioritize bytes 14, 15 for AirPods (these are the correct positions)
                if manufacturerData.count >= 16 {
                    let rightBattery = Int(manufacturerData[14])
                    let leftBattery = Int(manufacturerData[15])
                    
                    // Check if at least one earbud has valid battery (handles single AirPod case)
                    // 0 means disconnected, so we only use values > 0
                    let rightValid = rightBattery > 0 && rightBattery <= 100
                    let leftValid = leftBattery > 0 && leftBattery <= 100
                    
                    if rightValid && leftValid {
                        // Both earbuds connected - use minimum
                        let minBattery = min(leftBattery, rightBattery)
                        batteryReadCompletion?(minBattery)
                        return
                    } else if rightValid {
                        // Only right earbud connected
                        batteryReadCompletion?(rightBattery)
                        return
                    } else if leftValid {
                        // Only left earbud connected
                        batteryReadCompletion?(leftBattery)
                        return
                    }
                    // If both are 0 or invalid, continue to fallback
                }
                
                // Fallback: only use if bytes [14,15] are not valid
                // Skip bytes 4-15 to avoid false positives
                // But be more careful - don't use values that look like case battery or other data
                for i in 16..<manufacturerData.count {
                    let value = Int(manufacturerData[i])
                    if value >= 0 && value <= 100 {
                        if i + 1 < manufacturerData.count {
                            let next1 = Int(manufacturerData[i + 1])
                            // Only use if both values are reasonable battery levels
                            // Avoid using if one is 0 (might be case or disconnected earbud)
                            if next1 >= 1 && next1 <= 100 && value >= 1 && value <= 100 {
                                let minBattery = min(value, next1)
                                batteryReadCompletion?(minBattery)
                                return
                            }
                        }
                    }
                }
            }
        }
        
        // Track discovered peripherals
        if nameMatches && !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        batteryReadCompletion?(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Handle disconnection if needed
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            batteryReadCompletion?(nil)
            return
        }
        
        guard let services = peripheral.services else {
            batteryReadCompletion?(nil)
            return
        }
        
        let batteryServiceUUIDs: [CBUUID] = [
            CBUUID(string: "180F"),
            CBUUID(string: "FDCF"),
        ]
        
        for service in services {
            if batteryServiceUUIDs.contains(service.uuid) {
                peripheral.discoverCharacteristics(nil, for: service)
                return
            }
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        let batteryLevelUUID = CBUUID(string: "2A19")
        
        for characteristic in characteristics {
            if characteristic.uuid == batteryLevelUUID {
                peripheral.readValue(for: characteristic)
                return
            }
        }
        
        if let allServices = peripheral.services {
            var allChecked = true
            for svc in allServices {
                if svc.characteristics == nil {
                    allChecked = false
                    break
                }
            }
            
            if allChecked {
                batteryReadCompletion?(nil)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            batteryReadCompletion?(nil)
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        guard let data = characteristic.value, !data.isEmpty else {
            batteryReadCompletion?(nil)
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        let batteryLevel = Int(data[0])
        batteryReadCompletion?(batteryLevel)
        centralManager?.cancelPeripheralConnection(peripheral)
    }
}



