//
//  MusicPlayerClosed.swift
//  iNotch
//
//  Музыкальный плеер в закрытом состоянии notch с интегрированным sneak peek
//

import SwiftUI

struct MusicPlayerClosed: View {
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var coordinator = NotchCoordinator.shared
    @EnvironmentObject var vm: NotchViewModel
    
    private var isSneakPeekMode: Bool {
        coordinator.sneakPeek.show && coordinator.sneakPeek.type == .music
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack() {
                AlbumArtView()
                
                Spacer()
                
                AudioSpectrum()
                    .frame(width: 16, height: 14)
                
                Spacer().frame(width: 8)
            }
            
            if isSneakPeekMode {
                MarqueeText(
                    text: "\(musicManager.songTitle) - \(musicManager.artistName)",
                    textColor: Color(.white),
                    frameWidth: vm.closedNotchSize.width + 100,
                    minDuration: 0.01,
                    font: .system(size: 12, weight: .medium),
                    icon: "music.note",
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding(.vertical, isSneakPeekMode ? 12 : 0)
        .animation(.smooth(duration: 0.35), value: isSneakPeekMode)
    }
}


// MARK: - Previews

#Preview("Music Closed - Compact Mode") {
    let vm = NotchViewModel()
    
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        MusicPlayerClosed()
            .environmentObject(vm)
    }
    .frame(width: 400, height: 100)
    .onAppear {
        vm.closedNotchSize = CGSize(width: 250, height: 32)
        MusicManager.shared.songTitle = "Bohemian Rhapsody"
        MusicManager.shared.artistName = "Queen"
        MusicManager.shared.isPlaying = true
        // Без sneak peek
        NotchCoordinator.shared.sneakPeek.show = false
    }
}

#Preview("Music Closed - Sneak Peek Mode") {
    let vm = NotchViewModel()
    
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        MusicPlayerClosed()
            .environmentObject(vm)
    }
    .frame(width: 400, height: 100)
    .onAppear {
        vm.closedNotchSize = CGSize(width: 250, height: 32)
        MusicManager.shared.songTitle = "Храни Вас Бог"
        MusicManager.shared.artistName = "Григорий Лепс"
        MusicManager.shared.isPlaying = true
        
        // Включаем sneak peek через 0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotchCoordinator.shared.sneakPeek = SneakPeekState(
                show: true,
                type: .music,
                value: 0,
                icon: "music.note",
                title: "Music",
                titleColor: .white,
                valueColor: .white,
                iconColor: .white
            )
        }
    }
}

#Preview("Music Closed - Paused") {
    let vm = NotchViewModel()
    
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        MusicPlayerClosed()
            .environmentObject(vm)
    }
    .frame(width: 400, height: 100)
    .onAppear {
        vm.closedNotchSize = CGSize(width: 250, height: 32)
        MusicManager.shared.songTitle = "Paused Track"
        MusicManager.shared.artistName = "Artist"
        MusicManager.shared.isPlaying = false
        NotchCoordinator.shared.sneakPeek.show = false
    }
}

#Preview("Music Closed - Toggle Animation") {
    let vm = NotchViewModel()
    
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        MusicPlayerClosed()
            .environmentObject(vm)
    }
    .frame(width: 400, height: 100)
    .onAppear {
        vm.closedNotchSize = CGSize(width: 250, height: 32)
        MusicManager.shared.songTitle = "Very Long Song Title That Scrolls"
        MusicManager.shared.artistName = "Artist Name"
        MusicManager.shared.isPlaying = true
        
        // Toggle sneak peek every 3 seconds
        var showPeek = false
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            showPeek.toggle()
            if showPeek {
                NotchCoordinator.shared.sneakPeek = SneakPeekState(
                    show: true,
                    type: .music,
                    value: 0,
                    icon: "music.note",
                    title: "Music",
                    titleColor: .white,
                    valueColor: .white,
                    iconColor: .white
                )
            } else {
                NotchCoordinator.shared.sneakPeek.show = false
            }
        }
    }
}

