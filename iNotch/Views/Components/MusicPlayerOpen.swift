//
//  MusicPlayerOpen.swift
//  iNotch
//

import SwiftUI

struct MusicPlayerOpen: View {
    @ObservedObject var musicManager = MusicManager.shared
    
    // State для анимаций кнопок
    @State private var previousPressed = false
    @State private var playPausePressed = false
    @State private var nextPressed = false
    
    // State для hover эффектов
    @State private var previousHovered = false
    @State private var playPauseHovered = false
    @State private var nextHovered = false
    
    // State для progress bar
    @State private var sliderValue: Double = 0
    @State private var lastDragged: Date = Date()
    @State private var dragging: Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                AlbumArtView(size: 46, cornerRadius: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    MarqueeText(
                          text: musicManager.songTitle,
                          textColor: .white,
                          frameWidth: 200,
                          minDuration: 1,
                          font: .system(size: 14, weight: .semibold)
                      )
                    
                    Text(musicManager.artistName)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                AudioSpectrum()
                    .frame(width: 16, height: 14)
            }
            
            TimelineView(.animation(minimumInterval: musicManager.playbackRate > 0 ? 0.1 : nil)) { timeline in
                 MusicProgressView(
                     sliderValue: $sliderValue,
                     lastDragged: $lastDragged,
                     dragging: $dragging,
                     duration: musicManager.songDuration,
                     currentDate: timeline.date,
                     timestampDate: musicManager.timestampDate,
                     elapsedTime: musicManager.elapsedTime,
                     playbackRate: musicManager.playbackRate,
                     isPlaying: musicManager.isPlaying
                 ) { newValue in
                     musicManager.seek(to: newValue)
                 }
             }
            
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        previousPressed = true
                    }
                    musicManager.previousTrack()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            previousPressed = false
                        }
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .scaleEffect(previousPressed ? 0.85 : 1.0)
                        .opacity(previousPressed ? 0.7 : 1.0)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(previousHovered ? Color.white.opacity(0.15) : Color.clear)
                                .animation(.smooth(duration: 0.2), value: previousHovered)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.smooth(duration: 0.2)) {
                        previousHovered = hovering
                    }
                }
                
                // Play/Pause Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        playPausePressed = true
                    }
                    
                    musicManager.playPause()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            playPausePressed = false
                        }
                    }
                } label: {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .scaleEffect(playPausePressed ? 0.9 : 1.0)
                        .opacity(playPausePressed ? 0.8 : 1.0)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(playPauseHovered ? Color.white.opacity(0.15) : Color.clear)
                                .animation(.smooth(duration: 0.2), value: playPauseHovered)
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: musicManager.isPlaying)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.smooth(duration: 0.2)) {
                        playPauseHovered = hovering
                    }
                }
                
                // Next Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        nextPressed = true
                    }
                    
                    musicManager.nextTrack()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            nextPressed = false
                        }
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .scaleEffect(nextPressed ? 0.85 : 1.0)
                        .opacity(nextPressed ? 0.7 : 1.0)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(nextHovered ? Color.white.opacity(0.15) : Color.clear)
                                .animation(.smooth(duration: 0.2), value: nextHovered)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.smooth(duration: 0.2)) {
                        nextHovered = hovering
                    }
                }
            }
        }
        .onAppear {
            updateSliderValueFromCurrentTime()
        }
        .onChange(of: musicManager.elapsedTime) { _, newValue in
            if !dragging {
                sliderValue = newValue
                lastDragged = Date()
            }
        }
        .onChange(of: musicManager.timestampDate) { _, _ in
            if !dragging {
                updateSliderValueFromCurrentTime()
            }
        }
        .onChange(of: musicManager.songDuration) { _, newValue in
            if !dragging {
                sliderValue = min(sliderValue, newValue)
            }
        }
    }
    
    private func updateSliderValueFromCurrentTime() {
            let now = Date()
            let timeDifference = musicManager.isPlaying ? now.timeIntervalSince(musicManager.timestampDate) : 0
            let calculatedTime = musicManager.elapsedTime + (timeDifference * musicManager.playbackRate)
            sliderValue = min(calculatedTime, musicManager.songDuration > 0 ? musicManager.songDuration : calculatedTime)
            lastDragged = Date()
        }
}

// MARK: - MusicProgressView

struct MusicProgressView: View {
    @Binding var sliderValue: Double
    @Binding var lastDragged: Date
    @Binding var dragging: Bool
    
    let duration: Double
    let currentDate: Date
    let timestampDate: Date
    let elapsedTime: Double
    let playbackRate: Double
    let isPlaying: Bool
    var onValueChange: (Double) -> Void
    
    var currentElapsedTime: Double {
        if dragging {
            return sliderValue
        }
        
        // Вычисляем текущее время на основе timestamp и playback rate
        let timeDifference = isPlaying ? currentDate.timeIntervalSince(timestampDate) : 0
        let elapsed = elapsedTime + (timeDifference * playbackRate)
        return min(elapsed, duration > 0 ? duration : elapsed)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Text(formatTime(currentElapsedTime))
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .monospacedDigit()
            
            GeometryReader { geometry in
                ProgressView(value: duration > 0 ? currentElapsedTime / duration : 0)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(height: 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !dragging {
                                    dragging = true
                                }
                                let progress = value.location.x / geometry.size.width
                                let newValue = max(0, min(duration, progress * duration))
                                sliderValue = newValue
                            }
                            .onEnded { _ in
                                dragging = false
                                lastDragged = Date()
                                onValueChange(sliderValue)
                            }
                    )
            }
            .frame(height: 6)
            
            Text(formatTime(duration))
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .monospacedDigit()
        }
        .onChange(of: currentDate) { _, _ in
            if !dragging {
                let timeDifference = isPlaying ? currentDate.timeIntervalSince(timestampDate) : 0
                let calculated = elapsedTime + (timeDifference * playbackRate)
                sliderValue = min(calculated, duration > 0 ? duration : calculated)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
