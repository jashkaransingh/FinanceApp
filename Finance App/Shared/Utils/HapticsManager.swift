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

enum HapticsManager {

    // Keep generators alive (less lag)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)

    static func prepare() {
        DispatchQueue.main.async {
            notification.prepare()
            selection.prepare()
            light.prepare()
            medium.prepare()
            heavy.prepare()
        }
    }

    static func trigger(_ type: HapticType) {
        DispatchQueue.main.async {
            // Prepare right before firing for best feel
            prepare()

            switch type {
            case .success: notification.notificationOccurred(.success)
            case .warning: notification.notificationOccurred(.warning)
            case .error:   notification.notificationOccurred(.error)
            case .light:   light.impactOccurred()
            case .medium:  medium.impactOccurred()
            case .heavy:   heavy.impactOccurred()
            case .selection: selection.selectionChanged()
            }
        }
    }
}

