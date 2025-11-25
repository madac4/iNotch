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
        let barCount = 6
        let spacing: CGFloat = barWidth - 0.5
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
                xRadius: barWidth,
                yRadius: barWidth
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
            animation.toValue = CGFloat.random(in: 0.15 ... 1.0) 
            animation.duration = 0.3
            animation.autoreverses = true
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
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
            barLayer.transform = CATransform3DMakeScale(1, 0.35, 1)  // ← Changed from 0.2 to 0.35
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

// MARK: - SwiftUI Wrapper (for masking)

struct AudioSpectrumView: NSViewRepresentable {
    @Binding var isPlaying: Bool
    
    func makeNSView(context: Context) -> AudioSpectrumNSView {
        let spectrum = AudioSpectrumNSView()
        spectrum.setPlaying(isPlaying)
        return spectrum
    }
    
    func updateNSView(_ nsView: AudioSpectrumNSView, context: Context) {
        nsView.setPlaying(isPlaying)
    }
}

// MARK: - Gradient Spectrum View (boring.notch style)

struct AudioSpectrum: View {
    @ObservedObject var musicManager = MusicManager.shared
    var useAlbumArtColor: Bool = true
    
    private func ensureVisibleColor(_ color: NSColor) -> NSColor {
        guard let rgbColor = color.usingColorSpace(.sRGB) else { return .gray }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let perceivedBrightness = (0.2126 * red + 0.7152 * green + 0.0722 * blue)
        
        if perceivedBrightness < 0.2 {
            let scale = 0.2 / max(perceivedBrightness, 0.01)
            return NSColor(
                red: min(red * scale, 1.0),
                green: min(green * scale, 1.0),
                blue: min(blue * scale, 1.0),
                alpha: alpha
            )
        }
        
        return color
    }
    
    var body: some View {
        Rectangle()
            .fill(
                useAlbumArtColor
                    ? Color(nsColor: ensureVisibleColor(musicManager.avgColor)).gradient
                    : Color.gray.gradient
            )
            .mask {
                AudioSpectrumView(isPlaying: $musicManager.isPlaying)
                    .frame(width: 16, height: 12)
            }
    }
}
