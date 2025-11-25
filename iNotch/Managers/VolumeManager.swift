//
//  VolumeManager.swift
//  iNotch
//
//  Fixed version with proper listener cleanup
//

import Foundation
import CoreAudio
import Combine
import AudioToolbox

class VolumeManager: ObservableObject {
    static let shared = VolumeManager()
    
    @Published private(set) var currentVolume: Float = 0.0
    @Published private(set) var isMuted: Bool = false
    
    private var deviceID: AudioDeviceID = 0
    private var lastVolume: Float = 0.0
    private var debounceTimer: Timer?
    
    let volumeChanged = PassthroughSubject<Float, Never>()
    
    // ← ДОБАВЛЕНО: Сохраняем указатели для cleanup
    private var listenerClientData: UnsafeMutablePointer<VolumeManager>?
    private var volumeListenerCallback: AudioObjectPropertyListenerProc?
    
    private var deviceChangeCallback: AudioObjectPropertyListenerProc?
    
    private init() {
        print("🎵 VolumeManager: Initializing...")
        setupDeviceChangeMonitoring();
        setupVolumeMonitoring()
        updateCurrentVolume()
        print("🎵 VolumeManager: Initial volume: \(Int(currentVolume * 100))%")
    }
    
    private func setupVolumeMonitoring() {
        deviceID = getDefaultOutputDevice()
        
        guard deviceID != 0 else {
            print("❌ VolumeManager: Failed to get default output device")
            return
        }
        
        print("🎵 VolumeManager: Device ID: \(deviceID)")
        
        // Создаём callback
        let callback: AudioObjectPropertyListenerProc = { (
            inObjectID: AudioObjectID,
            inNumberAddresses: UInt32,
            inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
            inClientData: UnsafeMutableRawPointer?
        ) -> OSStatus in
            
            print("🔔 VolumeManager: Callback triggered!")
            
            guard let managerPointer = inClientData?.assumingMemoryBound(to: VolumeManager.self) else {
                print("❌ VolumeManager: Failed to get manager pointer")
                return noErr
            }
            
            let manager = managerPointer.pointee
            
            DispatchQueue.main.async {
                manager.updateCurrentVolume()
            }
            
            return noErr
        }
        
        // Сохраняем callback
        self.volumeListenerCallback = callback
        
        // Создаём pointer для self
        let selfPointer = UnsafeMutablePointer<VolumeManager>.allocate(capacity: 1)
        selfPointer.initialize(to: self)
        
        // Сохраняем pointer
        self.listenerClientData = selfPointer
        
        // Регистрируем listener для VirtualMainVolume
        var volumeAddress = AudioObjectPropertyAddress(
           mSelector: kAudioDevicePropertyVolumeScalar,
           mScope: kAudioDevicePropertyScopeOutput,
           mElement: 0
       )
        
        let volumeStatus = AudioObjectAddPropertyListener(
            deviceID,
            &volumeAddress,
            callback,
            selfPointer
        )
        
        if volumeStatus != noErr {
            print("❌ VolumeManager: Failed to add volume listener, status: \(volumeStatus)")
        } else {
            print("✅ VolumeManager: Volume monitoring started (device: \(deviceID))")
        }
        
        // Регистрируем listener для Mute
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let muteStatus = AudioObjectAddPropertyListener(
            deviceID,
            &muteAddress,
            callback,
            selfPointer
        )
        
        if muteStatus != noErr {
            print("⚠️ VolumeManager: Failed to add mute listener, status: \(muteStatus)")
        } else {
            print("✅ VolumeManager: Mute monitoring started")
        }
    }
    
    private func setupDeviceChangeMonitoring(){
        let callback: AudioObjectPropertyListenerProc = { (
                inObjectID: AudioObjectID,
                inNumberAddresses: UInt32,
                inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
                inClientData: UnsafeMutableRawPointer?
            ) -> OSStatus in
              
            print("🔄 VolumeManager: Output device changed!")
          
              guard let managerPointer = inClientData?.assumingMemoryBound(to: VolumeManager.self) else {
                  return noErr
              }
              
              let manager = managerPointer.pointee
              
              DispatchQueue.main.async {
                  manager.handleDeviceChange()
              }
              
              return noErr
        }
          
          self.deviceChangeCallback = callback
          
          let selfPointer = UnsafeMutablePointer<VolumeManager>.allocate(capacity: 1)
          selfPointer.initialize(to: self)
          
          var address = AudioObjectPropertyAddress(
              mSelector: kAudioHardwarePropertyDefaultOutputDevice,  // ← Отслеживаем изменения default устройства
              mScope: kAudioObjectPropertyScopeGlobal,
              mElement: kAudioObjectPropertyElementMain
          )
          
          let status = AudioObjectAddPropertyListener(
              AudioObjectID(kAudioObjectSystemObject),  // ← System object (не конкретное устройство)
              &address,
              callback,
              selfPointer
          )
          
          if status != noErr {
              print("⚠️ VolumeManager: Failed to add device change listener, status: \(status)")
          } else {
              print("✅ VolumeManager: Device change monitoring started")
          }
    }
    
    private func handleDeviceChange() {
        print("🔄 VolumeManager: Reinitializing for new device...")
        
        // Удаляем старые listeners
        removeVolumeListeners()
        
        // Получаем новое устройство и настраиваем listeners
        deviceID = getDefaultOutputDevice()
        
        if deviceID != 0 {
            setupVolumeMonitoring()
            updateCurrentVolume()
            print("✅ VolumeManager: Successfully switched to new device (ID: \(deviceID))")
        } else {
            print("❌ VolumeManager: Failed to get new device")
        }
    }
    
    private func removeVolumeListeners() {
         guard deviceID != 0,
               let callback = volumeListenerCallback,
               let clientData = listenerClientData else {
             return
         }
         
         print("🧹 VolumeManager: Removing old listeners...")
         
         // Volume listener
         var volumeAddress = AudioObjectPropertyAddress(
             mSelector: kAudioDevicePropertyVolumeScalar,
             mScope: kAudioDevicePropertyScopeOutput,
             mElement: 0
         )
         
         AudioObjectRemovePropertyListener(deviceID, &volumeAddress, callback, clientData)
         
         // Mute listener
         var muteAddress = AudioObjectPropertyAddress(
             mSelector: kAudioDevicePropertyMute,
             mScope: kAudioDevicePropertyScopeOutput,
             mElement: kAudioObjectPropertyElementMain
         )
         
         AudioObjectRemovePropertyListener(deviceID, &muteAddress, callback, clientData)
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
            print("❌ VolumeManager: Failed to get default output device, status: \(status)")
            return 0
        }
        
        if let deviceName = getDeviceName(deviceID) {
              print("🎧 VolumeManager: Current device: \(deviceName) (ID: \(deviceID))")
          }
        
        return deviceID
    }
    
//    private func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
//        var address = AudioObjectPropertyAddress(
//            mSelector: kAudioObjectPropertyName,
//            mScope: kAudioObjectPropertyScopeGlobal,
//            mElement: kAudioObjectPropertyElementMain
//        )
//        
//        var name: CFString = "" as CFString
//        var nameSize = UInt32(MemoryLayout<CFString>.size)
//        
//        let status = AudioObjectGetPropertyData(
//            deviceID,
//            &address,
//            0,
//            nil,
//            &nameSize,
//            &name
//        )
//        
//        return status == noErr ? (name as String) : nil
//    }
    
    private func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
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
    
    private func updateCurrentVolume() {
        guard deviceID != 0 else {
            print("❌ VolumeManager: deviceID is 0")
            return
        }
        
        var volume: Float32 = 0
        var volumeSize = UInt32(MemoryLayout<Float32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &volumeSize,
            &volume
        )
        
        if status == noErr {
            let muted = checkIfMuted()
            
            print("🔊 VolumeManager: Current volume: \(volume), previous: \(lastVolume), muted: \(muted)")
            
            if abs(volume - lastVolume) > 0.001 || muted != isMuted {
                lastVolume = volume
                currentVolume = volume
                isMuted = muted
                
                print("🔊 VolumeManager: Volume changed to \(Int(volume * 100))% (muted: \(muted))")
                
                debounceTimer?.invalidate()
                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    print("📤 VolumeManager: Sending volume event: \(volume)")
                    self.volumeChanged.send(volume)
                }
            }
        } else {
            print("❌ VolumeManager: Failed to get volume, status: \(status)")
        }
    }
    
    private func checkIfMuted() -> Bool {
        guard deviceID != 0 else { return false }
        
        var muted: UInt32 = 0
        var mutedSize = UInt32(MemoryLayout<UInt32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &mutedSize,
            &muted
        )
        
        return status == noErr && muted == 1
    }
    
    func setVolume(_ volume: Float) {
        guard deviceID != 0 else { return }
        
        var newVolume = max(0.0, min(1.0, volume))
        let volumeSize = UInt32(MemoryLayout<Float32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectSetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            volumeSize,
            &newVolume
        )
    }
    
    func speakerIcon(for volume: Float) -> String {
        if isMuted || volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    deinit {
        print("🧹 VolumeManager: Cleaning up...")
        
        // Удаляем volume listeners
        removeVolumeListeners()
        
        // Удаляем device change listener
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
        
        // Освобождаем память
        if let clientData = listenerClientData {
            clientData.deinitialize(count: 1)
            clientData.deallocate()
        }
        
        print("✅ VolumeManager: Cleanup complete")
    }
}
