//
//  DeviceConnectivityManager.swift
//  iNotch
//
//  Created by Petru Orbu on 27.11.2025.
//

import Foundation
import CoreAudio
import IOBluetooth
import Combine
import SwiftUI
import IOKit
import IOKit.hid

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
	case moved(DeviceInfo, toDevice: String?)
	case batteryUpdated(DeviceInfo)
}

class ConnectivityManager: ObservableObject {
	static let shared = ConnectivityManager()

    @Published var connectionEvent = PassthroughSubject<ConnectivityEvent, Never>()
	@Published var previousDevice: DeviceInfo?
	@Published var currentDevice: DeviceInfo? {
		didSet {
			if let device = currentDevice {
				print("   └─ Device ID: \(device.deviceID)")
				print("   └─ Name: \(device.name)")
				print("   └─ Is Bluetooth: \(device.isBluetooth)")
				print("   └─ Battery: \(device.batteryLevel?.description ?? "N/A")%")
				print("   └─ BT Address: \(device.bluetoothAddress ?? "N/A")")
			} else {
				print("   └─ Device: nil (no device)")
			}
		}
	}

	private var deviceChangeCallback: AudioObjectPropertyListenerProc?
	private var cancellables = Set<AnyCancellable>()
	private var deviceID: AudioDeviceID = 0

	private init() {
		setupDeviceMonitoring()
		checkCurrentDevice()
	}

    private func setupDeviceMonitoring() {
        let callback: AudioObjectPropertyListenerProc = { (
            inObjectID: AudioObjectID,
            inNumberAddresses: UInt32,
            inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
            inClientData: UnsafeMutableRawPointer?
        ) -> OSStatus in
            guard let managerPointer = inClientData?.assumingMemoryBound(to: ConnectivityManager.self) else {
                print("   ❌ Failed to get manager pointer")
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
		print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("🔄 DeviceConnectionManager: Handling device change...")
		
		let oldDevice = currentDevice
		print("📦 Previous device state:")
		if let old = oldDevice {
			print("   └─ ID: \(old.deviceID)")
			print("   └─ Name: \(old.name)")
			print("   └─ Is Bluetooth: \(old.isBluetooth)")
			print("   └─ Battery: \(old.batteryLevel?.description ?? "N/A")%")
		} else {
			print("   └─ No previous device")
		}
		
		checkCurrentDevice()
		
		print("📦 New device state:")
		if let new = currentDevice {
			print("   └─ ID: \(new.deviceID)")
			print("   └─ Name: \(new.name)")
			print("   └─ Is Bluetooth: \(new.isBluetooth)")
			print("   └─ Battery: \(new.batteryLevel?.description ?? "N/A")%")
		} else {
			print("   └─ No current device")
		}

		if let newDevice = currentDevice {
            if let old = oldDevice {
                // Device changed
                if old.deviceID != newDevice.deviceID {
					print("🔄 Device ID changed: \(old.deviceID) → \(newDevice.deviceID)")
                    // Check if old device is still available (moved to another device)
                    let stillAvailable = isDeviceStillAvailable(oldDevice: old)
					print("   └─ Old device still available: \(stillAvailable)")
					
                    if stillAvailable {
						print("📤 Sending .moved event")
						print("   └─ Device: \(old.name)")
						print("   └─ Moved to: \(newDevice.name)")
                        connectionEvent.send(.moved(old, toDevice: newDevice.name))
                    } else {
						print("📤 Sending .disconnected event")
						print("   └─ Device: \(old.name)")
                        connectionEvent.send(.disconnected(old))
                    }
					print("📤 Sending .connected event")
					print("   └─ Device: \(newDevice.name)")
                    connectionEvent.send(.connected(newDevice))
                } else {
					print("✅ Same device ID (\(newDevice.deviceID)), checking for battery update...")
                    // Same device, might be battery update
                    if old.batteryLevel != newDevice.batteryLevel {
						print("🔋 Battery level changed: \(old.batteryLevel?.description ?? "N/A")% → \(newDevice.batteryLevel?.description ?? "N/A")%")
						print("📤 Sending .batteryUpdated event")
                        connectionEvent.send(.batteryUpdated(newDevice))
                    } else {
						print("   └─ No battery change detected")
					}
                }
            } else {
                // First connection
				print("🆕 First device connection detected")
				print("📤 Sending .connected event")
				print("   └─ Device: \(newDevice.name)")
                connectionEvent.send(.connected(newDevice))
            }
        } else if let old = oldDevice {
            // Device disconnected
			print("❌ Device disconnected")
			print("📤 Sending .disconnected event")
			print("   └─ Device: \(old.name)")
            connectionEvent.send(.disconnected(old))
        }
		
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	}

	private func checkCurrentDevice() {
        let newDeviceID = getDefaultOutputDevice()
        
        guard newDeviceID != 0 else {
            currentDevice = nil
            return
        }
        		
        if newDeviceID != deviceID {
			print("   └─ Device ID changed: \(deviceID) → \(newDeviceID)")
            previousDevice = currentDevice
			if let prev = previousDevice {
				print("   └─ Previous device saved: \(prev.name)")
			}
            deviceID = newDeviceID
            
            if let deviceInfo = getDeviceInfo(deviceID: newDeviceID) {
				print("   ✅ Successfully retrieved device info")
                currentDevice = deviceInfo
            } else {
				print("   ❌ Failed to retrieve device info for ID: \(newDeviceID)")
			}
        } else {
			print("   └─ Same device ID, checking for updates...")
            if var deviceInfo = currentDevice {
                // Update battery for same device
                if let updatedInfo = getDeviceInfo(deviceID: newDeviceID) {
					print("   └─ Updating device info...")
                    deviceInfo = updatedInfo
                    currentDevice = deviceInfo
                }
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
		print("   🔍 Getting device info for ID: \(deviceID)...")
        guard let deviceName = getDeviceName(deviceID: deviceID) else {
			print("   ❌ Failed to get device name")
            return nil
        }
        
		print("   └─ Device name: \(deviceName)")
        let isBluetooth = isBluetoothDevice(deviceName: deviceName)
		print("   └─ Is Bluetooth: \(isBluetooth)")
        
        let batteryLevel = isBluetooth ? getBluetoothBattery(deviceName: deviceName) : nil
		if let battery = batteryLevel {
			print("   └─ Battery level: \(battery)%")
		} else {
			print("   └─ Battery level: N/A")
		}
        
        let bluetoothAddress = isBluetooth ? getBluetoothAddress(deviceName: deviceName) : nil
		if let address = bluetoothAddress {
			print("   └─ Bluetooth address: \(address)")
		} else {
			print("   └─ Bluetooth address: N/A")
		}
        
        let deviceInfo = DeviceInfo(
            deviceID: deviceID,
            name: deviceName,
            isBluetooth: isBluetooth,
            batteryLevel: batteryLevel,
            bluetoothAddress: bluetoothAddress
        )
		
		print("   ✅ Device info created successfully")
        return deviceInfo
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
			print("      ❌ Failed to get device name size, status: \(status)")
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
			print("      ❌ Failed to get device name, status: \(status)")
            return nil
        }
        return name
    }
    
    private func isBluetoothDevice(deviceName: String) -> Bool {
        let lowercased = deviceName.lowercased()
        let isBT = lowercased.contains("airpods") ||
               lowercased.contains("airpod") ||
               lowercased.contains("bluetooth") ||
               lowercased.contains("beats")
		print("      🔍 Checking if '\(deviceName)' is Bluetooth device: \(isBT)")
        return isBT
    }
    
private func getBluetoothBattery(deviceName: String) -> Int? {
    return nil
}

/// Helper to get device ID by name
private func getDeviceIDByName(deviceName: String) -> AudioDeviceID? {
	var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
	var deviceID: AudioDeviceID = 0
	
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
        print("      🔍 Getting Bluetooth address for: \(deviceName)...")
        
        // Use a semaphore to wait for the result from background queue
        let semaphore = DispatchSemaphore(value: 0)
        var result: String? = nil
        
        // Perform Bluetooth operations on a background queue to avoid QoS inversion
        let backgroundQueue = DispatchQueue(label: "com.inotch.bluetooth", qos: .utility)
        
        backgroundQueue.async { [weak self] in
            defer {
                semaphore.signal()
            }
            
            // This may still cause XPC errors, but at least it's on a background thread
            do {
                guard let pairedDevices = IOBluetoothDevice.pairedDevices() else {
                    print("      └─ ❌ No paired devices found")
                    return
                }
                
                for device in pairedDevices {
                    if let btDevice = device as? IOBluetoothDevice {
                        if btDevice.name == deviceName || deviceName.contains(btDevice.name ?? "") {
                            let address = btDevice.addressString
                            print("      └─ ✅ Found address: \(address ?? "N/A")")
                            result = address
                            return
                        }
                    }
                }
                
                print("      └─ ❌ Address not found")
            } catch {
                print("      └─ ❌ Error accessing Bluetooth: \(error.localizedDescription)")
            }
        }
        
        return result
    }
    
    private func isDeviceStillAvailable(oldDevice: DeviceInfo) -> Bool {
		print("      🔍 Checking if device is still available...")
        // Check if the old device is still in the system (paired but connected elsewhere)
        if oldDevice.isBluetooth, let address = oldDevice.bluetoothAddress {
			print("      └─ Checking Bluetooth device with address: \(address)")
            let pairedDevices = IOBluetoothDevice.pairedDevices()
            for device in pairedDevices ?? [] {
                if let btDevice = device as? IOBluetoothDevice {
                    if btDevice.addressString == address {
                        // Device is still paired, might be connected elsewhere
						print("      └─ ✅ Device is still paired")
                        return true
                    }
                }
            }
			print("      └─ ❌ Device not found in paired devices")
        } else {
			print("      └─ ⚠️ Not a Bluetooth device or no address available")
		}
        return false
    }
    
    func reconnectToDevice(_ deviceInfo: DeviceInfo) {
		print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("🔌 DeviceConnectionManager: Attempting to reconnect to device...")
		print("   └─ Device: \(deviceInfo.name)")
		print("   └─ Is Bluetooth: \(deviceInfo.isBluetooth)")
		print("   └─ Address: \(deviceInfo.bluetoothAddress ?? "N/A")")
		
        // Attempt to reconnect to the device
        if deviceInfo.isBluetooth, let address = deviceInfo.bluetoothAddress {
            let pairedDevices = IOBluetoothDevice.pairedDevices()
			print("   └─ Searching in \(pairedDevices?.count ?? 0) paired devices...")
            for device in pairedDevices ?? [] {
                if let btDevice = device as? IOBluetoothDevice {
                    if btDevice.addressString == address {
						print("   └─ ✅ Found device, attempting connection...")
                        // Try to connect
                        let result = btDevice.openConnection()
                        if result == kIOReturnSuccess {
                            print("   ✅ Successfully reconnected to \(deviceInfo.name)")
                            // The device change will be detected automatically
                        } else {
                            print("   ❌ Failed to reconnect to \(deviceInfo.name), error: \(result)")
                        }
						print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                        return
                    }
                }
            }
			print("   ❌ Device not found in paired devices")
        } else {
			print("   ⚠️ Cannot reconnect: Not a Bluetooth device or no address")
		}
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    deinit {
		print("🧹 DeviceConnectionManager: Cleaning up...")
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
		print("✅ DeviceConnectionManager: Cleanup complete")
    }
}

