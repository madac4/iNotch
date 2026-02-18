//
//  NowPlayingController.swift
//  iNotch
//
//  boring.notch архитектура с MediaRemote.framework
//

import AppKit
import Combine
import Foundation

final class NowPlayingController: ObservableObject, MediaControllerProtocol {
    // MARK: - Properties
    
    @Published private(set) var playbackState: PlaybackState = .init(
        bundleIdentifier: "com.apple.Music"
    )
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        $playbackState.eraseToAnyPublisher()
    }
    
    // MARK: - MediaRemote Functions
    
    private let mediaRemoteBundle: CFBundle
    private let MRMediaRemoteSendCommandFunction: @convention(c) (Int, AnyObject?) -> Void
    private let MRMediaRemoteSetElapsedTimeFunction: @convention(c) (Double) -> Void
    private let MRMediaRemoteSetShuffleModeFunction: @convention(c) (Int) -> Void
    private let MRMediaRemoteSetRepeatModeFunction: @convention(c) (Int) -> Void
    
    private var process: Process?
    private var pipeHandler: JSONLinesPipeHandler?
    private var streamTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init?() {
        
        // Загружаем MediaRemote.framework
        guard
            let bundle = CFBundleCreate(
                kCFAllocatorDefault,
                NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
            ),
            let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(
                bundle, "MRMediaRemoteSendCommand" as CFString
            ),
            let MRMediaRemoteSetElapsedTimePointer = CFBundleGetFunctionPointerForName(
                bundle, "MRMediaRemoteSetElapsedTime" as CFString
            ),
            let MRMediaRemoteSetShuffleModePointer = CFBundleGetFunctionPointerForName(
                bundle, "MRMediaRemoteSetShuffleMode" as CFString
            ),
            let MRMediaRemoteSetRepeatModePointer = CFBundleGetFunctionPointerForName(
                bundle, "MRMediaRemoteSetRepeatMode" as CFString
            )
        else {
            print("❌ Failed to load MediaRemote.framework")
            return nil
        }
        
        self.mediaRemoteBundle = bundle
        self.MRMediaRemoteSendCommandFunction = unsafeBitCast(
            MRMediaRemoteSendCommandPointer,
            to: (@convention(c) (Int, AnyObject?) -> Void).self
        )
        self.MRMediaRemoteSetElapsedTimeFunction = unsafeBitCast(
            MRMediaRemoteSetElapsedTimePointer,
            to: (@convention(c) (Double) -> Void).self
        )
        self.MRMediaRemoteSetShuffleModeFunction = unsafeBitCast(
            MRMediaRemoteSetShuffleModePointer,
            to: (@convention(c) (Int) -> Void).self
        )
        self.MRMediaRemoteSetRepeatModeFunction = unsafeBitCast(
            MRMediaRemoteSetRepeatModePointer,
            to: (@convention(c) (Int) -> Void).self
        )
                
        // Запускаем Perl адаптер
        Task { await setupNowPlayingObserver() }
    }
    
    deinit {
        streamTask?.cancel()
        
        if let pipeHandler = self.pipeHandler {
            Task { await pipeHandler.close() }
        }
        
        if let process = self.process {
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
        }
        
        self.process = nil
        self.pipeHandler = nil
    }
    
    // MARK: - Protocol Implementation
    
    func play() async {
        MRMediaRemoteSendCommandFunction(0, nil) // kMRPlay
    }
    
    func pause() async {
        MRMediaRemoteSendCommandFunction(1, nil) // kMRPause
    }
    
    func togglePlay() async {
        MRMediaRemoteSendCommandFunction(2, nil) // kMRTogglePlayPause
    }
    
    func nextTrack() async {
        MRMediaRemoteSendCommandFunction(4, nil) // kMRNextTrack
    }
    
    func previousTrack() async {
        MRMediaRemoteSendCommandFunction(5, nil) // kMRPreviousTrack
    }
    
    func seek(to time: Double) async {
        MRMediaRemoteSetElapsedTimeFunction(time)
    }
    
    func isActive() -> Bool {
        return true
    }
    
    func toggleShuffle() async {
        MRMediaRemoteSetShuffleModeFunction(playbackState.isShuffled ? 3 : 1)
        playbackState.isShuffled.toggle()
    }
    
    func toggleRepeat() async {
        let newRepeatMode = (playbackState.repeatMode == .off)
            ? 3
            : (playbackState.repeatMode.rawValue - 1)
        playbackState.repeatMode = RepeatMode(rawValue: newRepeatMode) ?? .off
        MRMediaRemoteSetRepeatModeFunction(newRepeatMode)
    }
    
    func updatePlaybackInfo() async {
        // Stub - данные приходят через stream
    }
    
    // MARK: - Setup Methods
    
    private func setupNowPlayingObserver() async {
        let process = Process()
        
        guard
            let scriptURL = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "pl"),
            let frameworkPath = Bundle.main.privateFrameworksPath?
                .appending("/MediaRemoteAdapter.framework")
        else {
            print("❌ Could not find mediaremote-adapter.pl or framework path")
            return
        }
            
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [scriptURL.path, frameworkPath, "stream"]
        
        let pipeHandler = JSONLinesPipeHandler()
        process.standardOutput = await pipeHandler.getPipe()
        
        self.process = process
        self.pipeHandler = pipeHandler
        
        do {
            try process.run()
            streamTask = Task { [weak self] in
                await self?.processJSONStream()
            }
        } catch {
            print("❌ Failed to launch mediaremote-adapter.pl: \(error)")
        }
    }
    
    // MARK: - Async Stream Processing
    
    private func processJSONStream() async {
        guard let pipeHandler = self.pipeHandler else { return }
        
        await pipeHandler.readJSONLines(as: NowPlayingUpdate.self) { [weak self] update in
            await self?.handleAdapterUpdate(update)
        }
    }
    
    // MARK: - Update Methods
    
    private func handleAdapterUpdate(_ update: NowPlayingUpdate) async {
        let payload = update.payload
        let diff = update.diff ?? false
        
        let isPlaying = payload.playing ?? self.playbackState.isPlaying
        let hasDuration = (payload.duration ?? 0) > 0
        let hasArtwork = (payload.artworkData?.isEmpty == false)
        let isEmptyMetadata = payload.title?.isEmpty != false && payload.artist?.isEmpty != false && payload.album?.isEmpty != false
        let hasExistingTrack = self.playbackState.title != "No Track Playing"
        
        // Кейс: Активный переход или лаг обновления. Сохраняем метаданные если есть признаки жизни.
        if !diff && isEmptyMetadata && (isPlaying || hasDuration || hasArtwork) && hasExistingTrack {
            var currentState = self.playbackState
            currentState.isPlaying = isPlaying
            currentState.currentTime = payload.elapsedTime ?? self.playbackState.currentTime
            if let rate = payload.playbackRate, rate > 0 {
                currentState.playbackRate = rate
            }
            if let dateString = payload.timestamp,
               let date = ISO8601DateFormatter().date(from: dateString) {
                currentState.lastUpdated = date
            }
            // Artwork обновляем только если пришёл новый
            if let artworkDataString = payload.artworkData {
                currentState.artwork = Data(base64Encoded: artworkDataString.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            self.playbackState = currentState
            return
        }
        
        var newPlaybackState = PlaybackState(bundleIdentifier: playbackState.bundleIdentifier)
        
        // Обновляем поля (с поддержкой diff mode)
        newPlaybackState.title = payload.title ?? (diff ? self.playbackState.title : "No Track Playing")
        newPlaybackState.artist = payload.artist ?? (diff ? self.playbackState.artist : "Unknown Artist")
        newPlaybackState.album = payload.album ?? (diff ? self.playbackState.album : "Unknown Album")
        newPlaybackState.duration = payload.duration ?? (diff ? self.playbackState.duration : 0)
        newPlaybackState.currentTime = payload.elapsedTime ?? (diff ? self.playbackState.currentTime : 0)
        
        // Shuffle mode
        if let shuffleMode = payload.shuffleMode {
            newPlaybackState.isShuffled = shuffleMode != 1
        } else if !diff {
            newPlaybackState.isShuffled = false
        } else {
            newPlaybackState.isShuffled = self.playbackState.isShuffled
        }
        
        // Repeat mode
        if let repeatModeValue = payload.repeatMode {
            newPlaybackState.repeatMode = RepeatMode(rawValue: repeatModeValue) ?? .off
        } else if !diff {
            newPlaybackState.repeatMode = .off
        } else {
            newPlaybackState.repeatMode = self.playbackState.repeatMode
        }
        
        // Artwork (base64)
        if let artworkDataString = payload.artworkData {
            newPlaybackState.artwork = Data(
                base64Encoded: artworkDataString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else if !diff {
            newPlaybackState.artwork = nil
        }
        
        // Timestamp
        if let dateString = payload.timestamp,
           let date = ISO8601DateFormatter().date(from: dateString) {
            newPlaybackState.lastUpdated = date
        } else if !diff {
            newPlaybackState.lastUpdated = Date()
        } else {
            newPlaybackState.lastUpdated = self.playbackState.lastUpdated
        }
        
        newPlaybackState.playbackRate = payload.playbackRate ?? (diff ? self.playbackState.playbackRate : 1.0)
        newPlaybackState.isPlaying = payload.playing ?? (diff ? self.playbackState.isPlaying : false)
        newPlaybackState.bundleIdentifier = (
            payload.parentApplicationBundleIdentifier ??
            payload.bundleIdentifier ??
            (diff ? self.playbackState.bundleIdentifier : "com.apple.Music")
        )
        
        // Публикуем обновление
        self.playbackState = newPlaybackState
            }
}
