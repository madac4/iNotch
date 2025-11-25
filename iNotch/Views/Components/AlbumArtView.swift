//
//  AlbumArtView.swift
//  iNotch
//
//  Album Art компонент с flip анимацией (boring.notch style)
//

import SwiftUI

struct AlbumArtView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @EnvironmentObject var vm: NotchViewModel
    
    @State private var previousAlbumArt: NSImage? = nil
    @State private var isAnimating = false
    
    let size: CGFloat?
    let cornerRadius: CGFloat?
   
    init(size: CGFloat? = nil, cornerRadius: CGFloat? = nil) {
       self.size = size
       self.cornerRadius = cornerRadius
    }

    private var effectiveSize: CGFloat {
       size ?? (vm.closedNotchSize.height - 12)
    }

    private var effectiveCornerRadius: CGFloat {
       cornerRadius ?? 6
    }
    
    var body: some View {
        ZStack {
            if let previousArt = previousAlbumArt, isAnimating {
                Image(nsImage: previousArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: effectiveSize, height: effectiveSize)
                    .clipShape(RoundedRectangle(cornerRadius: effectiveCornerRadius))
                    .blur(radius: isAnimating ? 10 : 0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8),
                        value: isAnimating
                    )
            }
            
            if musicManager.albumArt.size.width > 64 {
                Image(nsImage: musicManager.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: effectiveSize, height: effectiveSize)
                    .clipShape(RoundedRectangle(cornerRadius: effectiveCornerRadius))
                    .blur(radius: isAnimating ? 10 : 0)
                    .opacity(isAnimating ? 0 : 1)
                    .scaleEffect(isAnimating ? 0.8 : 1.0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8),
                        value: isAnimating
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: effectiveCornerRadius)
                        .fill(Color(nsColor: musicManager.avgColor).opacity(0.2))
                        .frame(width: effectiveSize, height: effectiveSize)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundColor(Color(nsColor: musicManager.avgColor))
                }
            }
            
            if !musicManager.isPlaying {
                RoundedRectangle(cornerRadius: effectiveCornerRadius)
                    .fill(Color.black.opacity(0.7))
                    .frame(width: effectiveSize, height: effectiveSize)
                    .animation(.smooth(duration: 0.2), value: musicManager.isPlaying)
                
                if musicManager.trackChanged {
                    Image(systemName: "pause.fill")
                        .font(.system(size: effectiveSize * 0.5))
                        .foregroundColor(.white.opacity(0.9))
                        .animation(.smooth(duration: 0.2), value: musicManager.isPlaying)
                }
            }
        }
        .padding(.leading, 6)
        .onChange(of: musicManager.isFlipping) { _, isFlipping in
            if isFlipping {
                if musicManager.albumArt.size.width > 64 {
                    previousAlbumArt = musicManager.albumArt
                }
                
                withAnimation {
                    isAnimating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        isAnimating = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        previousAlbumArt = nil
                    }
                }
            }
        }
    }
}
