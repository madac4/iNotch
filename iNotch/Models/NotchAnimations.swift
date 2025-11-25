//
//  NotchAnimations.swift
//  iNotch
//
//  Created by Petru Orbu on 18.11.2025.
//

import SwiftUI

public class NotchAnimations {
    var animation: Animation {
        Animation.spring(.bouncy(duration:0.4))
    }
}



//public class BoringAnimations {
//    @Published var notchStyle: Style = .notch
//    
//    init() {
//        self.notchStyle = .notch
//    }
//    
//    var animation: Animation {
//        if #available(macOS 14.0, *), notchStyle == .notch {
//            Animation.spring(.bouncy(duration: 0.4))
//        } else {
//            Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.7)
//        }
//    }
//    
//    // TODO: Move all animations to this file
//    
//}
