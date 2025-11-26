//
//  MarqueeText.swift
//  iNotch
//
//  Точная копия boring.notch реализации + поддержка иконки (фиксированной)
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct MeasureSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        })
    }
}

struct MarqueeText: View {
    // Поддержка как @Binding, так и let text
    @Binding private var bindingText: String?
    let text: String
    
    let font: Font
    let nsFont: NSFont.TextStyle
    let textColor: Color
    let backgroundColor: Color
    let minDuration: Double
    let frameWidth: CGFloat
    
    // Icon properties
    let icon: String?
    let iconSize: CGFloat
    let iconColor: Color?
    let iconSpacing: CGFloat
    
    @State private var animate = false
    @State private var textSize: CGSize = .zero
    @State private var offset: CGFloat = 0
    
    // Инициализатор с Binding (как в boring.notch)
    init(_ text: Binding<String>, font: Font = .body, nsFont: NSFont.TextStyle = .body, textColor: Color = .primary, backgroundColor: Color = .clear, minDuration: Double = 3.0, frameWidth: CGFloat = 200) {
        _bindingText = Binding(
            get: { text.wrappedValue },
            set: { text.wrappedValue = $0 ?? "" }
        )
        self.text = text.wrappedValue
        self.font = font
        self.nsFont = nsFont
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.minDuration = minDuration
        self.frameWidth = frameWidth
        self.icon = nil
        self.iconSize = 14
        self.iconColor = nil
        self.iconSpacing = 4
    }
    
    // Инициализатор с let text (для обратной совместимости)
    init(
        text: String,
        textColor: Color = .white,
        frameWidth: CGFloat = 100,
        minDuration: Double = 3.0,
        font: Font = .system(size: 13, weight: .medium),
        icon: String? = nil,
        iconSize: CGFloat = 14,
        iconColor: Color? = nil,
        iconSpacing: CGFloat = 4
    ) {
        _bindingText = .constant(nil)
        self.text = text
        self.font = font
        self.nsFont = .body
        self.textColor = textColor
        self.backgroundColor = .clear
        self.minDuration = minDuration
        self.frameWidth = frameWidth
        self.icon = icon
        self.iconSize = iconSize
        self.iconColor = iconColor
        self.iconSpacing = iconSpacing
    }
    
    // Computed property для получения текущего текста
    private var currentText: String {
        bindingText ?? text
    }
    
    private var needsScrolling: Bool {
        textSize.width > frameWidth
    }
    
    private var finalIconColor: Color {
        iconColor ?? textColor
    }
    
    // Только текст для измерения (без иконки)
    @ViewBuilder
    private var textOnlyView: some View {
        Text(currentText)
            .font(font)
            .foregroundColor(textColor)
    }
    
    // Скроллируемый контент (только текст)
    @ViewBuilder
    private var scrollableContentView: some View {
        HStack(spacing: 20) {
            textOnlyView
            textOnlyView
                .opacity(needsScrolling ? 1 : 0)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: iconSpacing) {
                // Фиксированная иконка слева
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: iconSize))
                        .foregroundColor(finalIconColor)
                }
                
                // Скроллируемый текст
                ZStack(alignment: .leading) {
                    scrollableContentView
                        .id(currentText)
                        .fixedSize(horizontal: true, vertical: false)
                        .offset(x: self.animate ? offset : 0)
                        .animation(
                            self.animate ?
                                .linear(duration: Double(textSize.width / 30))
                                .delay(minDuration)
                                .repeatForever(autoreverses: false) : .none,
                            value: self.animate
                        )
                        .background(backgroundColor)
                        .modifier(MeasureSizeModifier())
                        .onPreferenceChange(SizePreferenceKey.self) { size in
                            print("📏 MarqueeText SIZE MEASURED: raw size=\(size)")
                            
                            self.textSize = CGSize(width: size.width / 2, height: NSFont.preferredFont(forTextStyle: nsFont).pointSize)
                            
                            print("📐 MarqueeText CALCULATED: textSize.width=\(self.textSize.width), frameWidth=\(frameWidth), iconWidth=\(icon != nil ? iconSize + iconSpacing : 0), availableWidth=\(frameWidth - (icon != nil ? iconSize + iconSpacing : 0)), needsScrolling=\(needsScrolling)")
                            
                            self.animate = false
                            self.offset = 0
                            
                            // Учитываем ширину иконки при проверке необходимости скролла
                            let availableWidth = frameWidth - (icon != nil ? iconSize + iconSpacing : 0)
                            let shouldScroll = self.textSize.width > availableWidth
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                if shouldScroll {
                                    self.animate = true
                                    self.offset = -(textSize.width + 10)
                                    print("✅ MarqueeText ANIMATION STARTED: animate=\(self.animate), offset=\(self.offset), duration=\(Double(textSize.width / 30))")
                                } else {
                                    print("❌ MarqueeText NO ANIMATION: Text fits in frame")
                                }
                            }
                        }
                }
                .frame(width: frameWidth - (icon != nil ? iconSize + iconSpacing : 0), alignment: .leading)
                .clipped()
            }
        }
        .frame(height: textSize.height * 1.3)
        .onChange(of: currentText) { oldValue, newValue in
            print("🔄 MarqueeText TEXT CHANGED: '\(oldValue)' -> '\(newValue)'")
        }
    }
}
