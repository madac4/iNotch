//
//  NotchContentView.swift
//  iNotch
//
//  Полная версия с Sneak Peek в стиле Dynamic Island
//

import SwiftUI
import Defaults

struct ContentView: View {
    // MARK: - Свойства
    
    @EnvironmentObject var vm: NotchViewModel
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var musicManager = MusicManager.shared
    
    @State private var isHovering: Bool = false
    @State private var hoverWorkItem: DispatchWorkItem?
    @State private var haptics: Bool = false

    
    private let zeroHeightHoverPadding: CGFloat = 10

    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            let mainLayout = NotchLayout()
                .frame(alignment: .top)
                .padding(
                    .horizontal,
                    vm.notchState == .open
                    ? Defaults[.cornerRadiusScaling]
                    ? (cornerRadiusInsets.opened.top)
                    : (cornerRadiusInsets.opened.bottom)
                    : cornerRadiusInsets.closed.bottom
                )
                .padding([.horizontal, .bottom], vm.notchState == .open ? 12 : 0)
                .background(.black)
                .mask {
                    NotchShape(
                        topCornerRadius: ((vm.notchState == .open) && Defaults[.cornerRadiusScaling])
                        ? cornerRadiusInsets.opened.top
                        : cornerRadiusInsets.closed.top,
                        bottomCornerRadius: ((vm.notchState == .open) && Defaults[.cornerRadiusScaling])
                        ? cornerRadiusInsets.opened.bottom
                        : cornerRadiusInsets.closed.bottom
                    )
                    .drawingGroup()
                }
            
            
            let currentNotchHeight: CGFloat = vm.notchState == .open 
                ? openNotchSize.height 
                : (coordinator.sneakPeek.show && coordinator.sneakPeek.type == .music 
                    ? vm.closedNotchSize.height + 30 
                    : vm.closedNotchSize.height)
            
            mainLayout
                .frame(height: currentNotchHeight, alignment: .top)
                .contentShape(Rectangle())
                .scaleEffect(
                    vm.notchState == .closed && isHovering ? 1.08 : 1.0,
                    anchor: .top
                )
                .animation(.bouncy.speed(1.2), value: isHovering)
                .animation(.spring.speed(1.2), value: vm.notchState)
                .animation(.smooth, value: vm.gestureProgress)
                .onHover { hovering in
                    handleHover(hovering)
                }
                .onTapGesture {
                    vm.toggle()
                    
                    if Defaults[.enableHaptics]{
                        haptics.toggle()
                    }
                }
                .panGesture(direction: .down) { translation, phase in
                    handleDownGesture(translation: translation, phase: phase)
                }
                .panGesture(direction: .up) { translation, phase in
                    handleUpGesture(translation: translation, phase: phase)
                }
                .sensoryFeedback(.alignment, trigger: haptics)
                .blur(radius: abs(vm.gestureProgress) > 0.3 ? min(abs(vm.gestureProgress), 8) : 0)
                .opacity(abs(vm.gestureProgress) > 0.3 ? min(abs(vm.gestureProgress * 2), 0.8) : 1)
        }
        .frame(
            maxWidth: openNotchSize.width,
            maxHeight: openNotchSize.height,
            alignment: .top
        )
        .shadow(
            color: (vm.notchState == .open || isHovering) ? .black.opacity(0.5) : .clear,
            radius: 12
        )
        .environmentObject(vm)
    }
    
    // MARK: - Layout
    
    @ViewBuilder
    func NotchLayout() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // ═══ SNEAK PEEK (только volume и battery, музыка - внутри MusicPlayerClosed) ═══
            if coordinator.sneakPeek.show && vm.notchState == .closed {
                let volumeWidth: CGFloat = Defaults[.showVolumeProgress]
                    ? vm.closedNotchSize.width * 2
                    : Defaults[.showVolumeLabel]
                    ? vm.closedNotchSize.width * 1.8
                    : vm.closedNotchSize.width * 1.3
                
                let connectivityWidth: CGFloat = Defaults[.warnOnLowDeviceBattery] && coordinator.sneakPeek.value < Defaults[.lowDeviceBatteryThreshold] && !coordinator.sneakPeek.title.isEmpty ? vm.closedNotchSize.width * 1.8 : vm.closedNotchSize.width * 1.3
                
                switch coordinator.sneakPeek.type {
                    case .volume:
                        VolumeSneakPeekView(state: coordinator.sneakPeek)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
                            .zIndex(100)
                            .frame(width: volumeWidth, height: vm.closedNotchSize.height)
                    
                    case .battery:
                        BatterySneakPeekView(state: coordinator.sneakPeek)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
                            .zIndex(100)
                            .frame(width: vm.closedNotchSize.width * 1.8, height: vm.closedNotchSize.height)
                    case .deviceConnection:
                       DeviceConnectionSneakPeek(state: coordinator.sneakPeek)
                           .transition(.asymmetric(
                               insertion: .scale(scale: 0.9).combined(with: .opacity),
                               removal: .scale(scale: 0.95).combined(with: .opacity)
                           ))
                           .zIndex(100)
                           .frame(width: connectivityWidth, height: vm.closedNotchSize.height)
                    case .music:
                        EmptyView()
                    
                    default:
                        EmptyView()
                }
            }
            
            // ═══ ОБЫЧНЫЙ КОНТЕНТ ═══
            if vm.notchState == .closed {
                // Для музыки всегда показываем компонент (он сам управляет sneak peek)
                // Для остальных - скрываем при sneak peek
                if !musicManager.isPlayerIdle && coordinator.sneakPeek.type == .music {
                    closedStateContent
                } else if !coordinator.sneakPeek.show {
                    closedStateContent
                }
            } else {
                openStateContent
            }
        }
    }
    
    // MARK: - Закрытое состояние
    
    @ViewBuilder
    var closedStateContent: some View {
        if !musicManager.isPlayerIdle || coordinator.sneakPeek.type == .music {
            MusicPlayerClosed()
                .frame(width: vm.closedNotchSize.width + 90, height: coordinator.sneakPeek.show ? vm.closedNotchSize.height + 30 : vm.closedNotchSize.height)
        } else {
            HStack() {}
                .frame(width: vm.closedNotchSize.width, height: vm.closedNotchSize.height)
        }
    }
    
    // MARK: - Открытое состояние
    
    @ViewBuilder
    var openStateContent: some View {
        if !musicManager.isPlayerIdle {
            VStack(spacing: 0) {
                MusicPlayerOpen()
                    .padding(.top, 40)
                    .frame(width: vm.closedNotchSize.width + 90)
            }
        } else {
            VStack(spacing: 0) {
                timeSection
            }
            .padding(.top, 32)
        }
    }
    
    @ViewBuilder
    var timeSection: some View {
        VStack(spacing: 8) {
            Text(currentTime)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .monospacedDigit()
            
            Text(currentDate)
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Вспомогательные свойства
    
    var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: Date())
    }
    
    // MARK: - Hover detection
    
    private func handleHover(_ hovering: Bool) {
        hoverWorkItem?.cancel()
        hoverWorkItem = nil
        
        if hovering {
            if vm.notchState == .closed && Defaults[.enableHaptics]{
                haptics.toggle()
            }
            
				withAnimation(.bouncy.speed(1.2)) {
					isHovering = true
				}
				
				if Defaults[.openOnHover] {
					let task = DispatchWorkItem {
						guard vm.notchState == .closed, isHovering else { return }
						vm.open()
					}
				
				hoverWorkItem = task
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: task)
				}
        } else {
			withAnimation(.bouncy.speed(1.2)) {
				isHovering = false
			}
			
			if Defaults[.openOnHover] {
				if vm.notchState == .open {
					vm.close()
				}
			}
        }
    }
    
    private func handleUpGesture(translation: CGFloat, phase: NSEvent.Phase){
        guard vm.notchState == .open, !vm.isHoveringCalendar, Defaults[.allowGestures] else {return}
        
        withAnimation(.smooth){
            vm.gestureProgress = (translation / Defaults[.gestureSensitivity]) * -20
        }
        
        if phase == .ended {
            withAnimation(.smooth){
                vm.gestureProgress = .zero
            }
        }
        
        if translation > Defaults[.gestureSensitivity]{
            withAnimation(.smooth){
                vm.gestureProgress = .zero
                isHovering = false
            }
            
            vm.close()
            
            if Defaults[.enableHaptics]{
                haptics.toggle()
            }
        }
        
    }
    
    private func handleDownGesture(translation: CGFloat, phase: NSEvent.Phase){
        guard vm.notchState == .closed, !coordinator.sneakPeek.show, Defaults[.allowGestures] else {return}
        
        withAnimation(.smooth){
            vm.gestureProgress = (translation / Defaults[.gestureSensitivity]) * 20
        }
        
        if phase == .ended {
            withAnimation(.smooth){
                vm.gestureProgress = .zero
            }
        }
        
        if translation > Defaults[.gestureSensitivity]{
            if Defaults[.enableHaptics]{
                haptics.toggle()
            }
            
            withAnimation(.smooth){
                vm.gestureProgress = .zero
            }
            
            vm.open()
        }
        
    }
}

