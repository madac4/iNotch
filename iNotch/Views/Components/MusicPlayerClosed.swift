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
                
                AudioSpectrum(useAlbumArtColor: true)
                    .frame(width: 16, height: 12)
                
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
