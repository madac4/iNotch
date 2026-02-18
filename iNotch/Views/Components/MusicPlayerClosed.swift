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
    
    // State для hover эффектов
    @State private var artworkHovered = false
    @State private var textHovered = false
    
    private var isSneakPeekMode: Bool {
        coordinator.sneakPeek.show && coordinator.sneakPeek.type == .music
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack() {
                AlbumArtView()
                    .scaleEffect(artworkHovered ? 1.1 : 1.0)
                    .opacity(artworkHovered ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: artworkHovered)
                    .onHover { hovering in
                        artworkHovered = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pointingHand.pop()
                        }
                    }
                    .onTapGesture {
                        musicManager.openMusicApp()
                    }
                
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
                .id(musicManager.songTitle)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 20)),
                    removal: .opacity.combined(with: .offset(x: -20))
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: musicManager.songTitle)
                .contentShape(Rectangle())
                .scaleEffect(textHovered ? 1.02 : 1.0)
                .opacity(textHovered ? 0.8 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textHovered)
                .onHover { hovering in
                    textHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pointingHand.pop()
                    }
                }
                .onTapGesture {
                    musicManager.openMusicApp()
                }
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
