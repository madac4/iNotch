//
//  AudioSpectrum.swift
//  iNotch
//
//  Beautiful audio spectrum visualizer (boring.notch style)
//  4 animated bars with random heights
//

import AppKit
import Cocoa
import SwiftUI

// MARK: - AudioSpectrum NSView

class AudioSpectrumNSView: NSView {
    private var barLayers: [CAShapeLayer] = []
    private var isPlaying: Bool = true
    private var animationTimer: Timer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBars()
    }

    private func setupBars() {
        let barWidth: CGFloat = 2
        let barCount = 5
        let spacing: CGFloat = barWidth
        let totalWidth = CGFloat(barCount) * (barWidth + spacing)
        let totalHeight: CGFloat = 14
        frame.size = CGSize(width: totalWidth, height: totalHeight)

        for i in 0 ..< barCount {
            let xPosition = CGFloat(i) * (barWidth + spacing)
            let barLayer = CAShapeLayer()
            barLayer.frame = CGRect(x: xPosition, y: 0, width: barWidth, height: totalHeight)
            barLayer.position = CGPoint(x: xPosition + barWidth / 2, y: totalHeight / 2)
            barLayer.fillColor = NSColor.white.cgColor
            
            let path = NSBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: barWidth, height: totalHeight),
                xRadius: barWidth / 2,
                yRadius: barWidth / 2
            )
            barLayer.path = path.cgPath
            
            barLayers.append(barLayer)
            layer?.addSublayer(barLayer)
        }
    }
    
    private func startAnimating() {
        guard animationTimer == nil else { return }
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.updateBars()
        }
    }
    
    private func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
        resetBars()
    }
    
    private func updateBars() {
        for barLayer in barLayers {
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = barLayer.presentation()?.value(forKeyPath: "transform.scale.y") ?? 0.35
            animation.toValue = CGFloat.random(in: 0.35 ... 1.0)
            animation.duration = 0.3
            animation.autoreverses = true
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
            // Optimize for 24 FPS on macOS 13+
            if #available(macOS 13.0, *) {
                animation.preferredFrameRateRange = CAFrameRateRange(
                    minimum: 24,
                    maximum: 24,
                    preferred: 24
                )
            }
            
            barLayer.add(animation, forKey: "scaleY")
        }
    }
    
    private func resetBars() {
        for barLayer in barLayers {
            barLayer.removeAllAnimations()
            barLayer.transform = CATransform3DMakeScale(1, 0.3, 1)
        }
    }
    
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
        if isPlaying {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
    
    func setColor(_ color: NSColor) {
        for barLayer in barLayers {
            barLayer.fillColor = color.cgColor
        }
    }
}

// MARK: - SwiftUI Wrapper

struct AudioSpectrum: NSViewRepresentable {
    @ObservedObject var musicManager = MusicManager.shared
    var color: NSColor? = nil
    
    func makeNSView(context: Context) -> AudioSpectrumNSView {
        let spectrum = AudioSpectrumNSView()
        spectrum.setPlaying(musicManager.isPlaying)
        if let customColor = color {
            spectrum.setColor(customColor)
        } else {
            spectrum.setColor(musicManager.avgColor)
        }
        return spectrum
    }
    
    func updateNSView(_ nsView: AudioSpectrumNSView, context: Context) {
        nsView.setPlaying(musicManager.isPlaying)
        if let customColor = color {
            nsView.setColor(customColor)
        } else {
            nsView.setColor(musicManager.avgColor)
        }
    }
}

// MARK: - Preview

#Preview("Audio Spectrum - Playing") {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        AudioSpectrum()
            .frame(width: 20, height: 14)
    }
    .frame(width: 100, height: 50)
    .onAppear {
        MusicManager.shared.isPlaying = true
    }
}

#Preview("Audio Spectrum - Paused") {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        AudioSpectrum()
            .frame(width: 20, height: 14)
    }
    .frame(width: 100, height: 50)
    .onAppear {
        MusicManager.shared.isPlaying = false
    }
}

#Preview("Audio Spectrum - Custom Color") {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        AudioSpectrum(color: .systemPurple)
            .frame(width: 20, height: 14)
    }
    .frame(width: 100, height: 50)
    .onAppear {
        MusicManager.shared.isPlaying = true
    }
}

