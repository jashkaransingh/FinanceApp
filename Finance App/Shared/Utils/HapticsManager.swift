//
//  HapticsManager.swift
//  Finance App
//
//  Created by Jas  on 6/10/25.
//

import UIKit

enum HapticType {
    case success
    case warning
    case error
    case light
    case medium
    case heavy
    case selection
}

struct HapticsManager {
    static func trigger(_ type: HapticType) {
        switch type {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

