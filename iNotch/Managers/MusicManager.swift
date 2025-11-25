//
//  MusicManager.swift
//  iNotch
//
//  boring.notch архитектура
//

import AppKit
import Combine
import SwiftUI

let defaultImage: NSImage = .init(
    systemSymbolName: "music.note",
    accessibilityDescription: "Album Art"
)!

class MusicManager: ObservableObject {
    // MARK: - Properties
    
    static let shared = MusicManager()
    private var cancellables = Set<AnyCancellable>()
    private var controllerCancellables = Set<AnyCancellable>()
    
    // Active controller
    private var activeController: (any MediaControllerProtocol)?
    
    // Published properties for UI
    @Published var songTitle: String = "No Track Playing"
    @Published var artistName: String = "Unknown Artist"
    @Published var albumArt: NSImage = defaultImage
    @Published var isPlaying = false
    @Published var album: String = "Unknown Album"
    @Published var isPlayerIdle: Bool = true
    @Published var avgColor: NSColor = .white
    @Published var bundleIdentifier: String? = nil
    @Published var songDuration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var timestampDate: Date = .init()
    @Published var playbackRate: Double = 1
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var isFlipping: Bool = false
    private var flipWorkItem: DispatchWorkItem?
    
    @Published var trackChanged: Bool = false
    
    private var artworkData: Data? = nil
    
    // MARK: - Initialization
    
    private init() {
        setupNowPlayingController()
    }
    
    deinit {
        destroy()
    }
    
    public func destroy() {
        cancellables.removeAll()
        controllerCancellables.removeAll()
        activeController = nil
    }
    
    // MARK: - Setup Methods
    
    private func setupNowPlayingController() {
        guard let controller = NowPlayingController() else {
            print("❌ Failed to create NowPlayingController")
            return
        }
        
        // Подписываемся на обновления
        controller.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateFromPlaybackState(state)
            }
            .store(in: &controllerCancellables)
        
        activeController = controller
    }
    
    // MARK: - Update Methods
    
 @MainActor
    private func updateFromPlaybackState(_ state: PlaybackState) {
       let trackChanged = state.title != self.songTitle || state.artist != self.artistName

       // Проверяем изменение playing состояния
       if state.isPlaying != self.isPlaying {
           withAnimation(.smooth) {
               self.isPlaying = state.isPlaying
               self.isPlayerIdle = !state.isPlaying && state.title == "No Track Playing" && !trackChanged
           }
       }

       // Обновляем artwork только если он действительно изменился
       let artworkChanged = state.artwork != nil && state.artwork != self.artworkData
       
       if artworkChanged, let artwork = state.artwork {
           self.updateArtwork(artwork)
           self.artworkData = state.artwork
       } else if state.artwork == nil && self.artworkData == nil {
           // Только если artwork был nil и остается nil - показываем default
           // НЕ сбрасываем если artwork временно nil при паузе
           if self.albumArt.size.width <= 64 {
               self.albumArt = defaultImage
           }
       }
       
       // Обновляем остальные поля
       if state.title != self.songTitle {
           self.songTitle = state.title
       }
       
       if state.artist != self.artistName {
           self.artistName = state.artist
       }
       
       if state.album != self.album {
           self.album = state.album
       }
       
       // ВАЖНО: Всегда обновляем elapsedTime и timestampDate на каждом обновлении
       // Это нужно для правильного расчета времени в TimelineView
       if state.currentTime != self.elapsedTime {
           self.elapsedTime = state.currentTime
       }
       
       // ВСЕГДА обновляем timestampDate на каждом обновлении состояния
       // Это критично для правильного расчета текущего времени
       self.timestampDate = state.lastUpdated
       
       if state.duration != self.songDuration {
           self.songDuration = state.duration
       }
       
       if state.playbackRate != self.playbackRate {
           self.playbackRate = state.playbackRate
       }
       
       if state.isShuffled != self.isShuffled {
           self.isShuffled = state.isShuffled
       }
       
       if state.bundleIdentifier != self.bundleIdentifier {
           self.bundleIdentifier = state.bundleIdentifier
       }
       
       if state.repeatMode != self.repeatMode {
           self.repeatMode = state.repeatMode
       }
       
       if trackChanged && !state.title.isEmpty && state.title != "No Track Playing" {
           self.trackChanged.toggle()
       }
    }
    
    private func triggerFlipAnimation() {
        // Cancel any existing animation
        flipWorkItem?.cancel()
        
        // Create a new animation
        let workItem = DispatchWorkItem { [weak self] in
            self?.isFlipping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.isFlipping = false
            }
        }
        
        flipWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
    
    private func updateArtwork(_ artworkData: Data) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let artworkImage = NSImage(data: artworkData) {
                DispatchQueue.main.async { [weak self] in
                    self?.albumArt = artworkImage
                    self?.calculateAverageColor()
                }
            }
        }
    }
    
    func calculateAverageColor() {
        albumArt.averageColor { [weak self] color in
            DispatchQueue.main.async {
                withAnimation(.smooth) {
                    self?.avgColor = color ?? .white
                }
            }
        }
    }
    
    // MARK: - Public Methods for controlling playback
    
    func playPause() {
        Task {
            await activeController?.togglePlay()
        }
    }
    
    func play() {
        Task {
            await activeController?.play()
        }
    }
    
    func pause() {
        Task {
            await activeController?.pause()
        }
    }
    
    func toggleShuffle() {
        Task {
            await activeController?.toggleShuffle()
        }
    }
    
    func toggleRepeat() {
        Task {
            await activeController?.toggleRepeat()
        }
    }
    
    func togglePlay() {
        Task {
            await activeController?.togglePlay()
        }
    }
    
    func nextTrack() {
        Task {
            await activeController?.nextTrack()
        }
    }
    
    func previousTrack() {
        Task {
            await activeController?.previousTrack()
        }
    }
    
    func seek(to position: TimeInterval) {
        Task {
            await activeController?.seek(to: position)
        }
    }
}

// MARK: - NSImage Extension (Average Color)

extension NSImage {
    func averageColor(completion: @escaping (NSColor?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                completion(nil)
                return
            }
            
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8
            
            var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
            
            guard let context = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                completion(nil)
                return
            }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            var totalRed: Int = 0
            var totalGreen: Int = 0
            var totalBlue: Int = 0
            let pixelCount = width * height
            
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * bytesPerPixel
                    totalRed += Int(pixelData[offset])
                    totalGreen += Int(pixelData[offset + 1])
                    totalBlue += Int(pixelData[offset + 2])
                }
            }
            
            let avgRed = CGFloat(totalRed) / CGFloat(pixelCount) / 255.0
            let avgGreen = CGFloat(totalGreen) / CGFloat(pixelCount) / 255.0
            let avgBlue = CGFloat(totalBlue) / CGFloat(pixelCount) / 255.0
            
            completion(NSColor(red: avgRed, green: avgGreen, blue: avgBlue, alpha: 1.0))
        }
    }
}
