//
//  ThemeManager.swift
//  Finance App
//
//  Created by Jas  on 7/30/25.
//

import UIKit

final class ThemeManager {
    
    static let shared = ThemeManager()
    
    // String-backed (stable) values
    enum Theme: String, CaseIterable {
        case system
        case light
        case dark
        
        // Legacy support: map old indices 0/1/2 → enum
        init?(legacyIndex: Int) {
            switch legacyIndex {
            case 0: self = .system
            case 1: self = .light
            case 2: self = .dark
            default: return nil
            }
        }
    }
    
    /// Returns the current theme, migrating an old Int value to String if needed.
    static func currentTheme() -> Theme {
        let defaults = UserDefaults.standard
        // Preferred: read the string
        if let raw = defaults.string(forKey: SettingsKeys.appAppearance),
           let theme = Theme(rawValue: raw) {
            return theme
        }
        // Migration path: if there’s an Int stored under the same key, convert it
        if let legacy = defaults.object(forKey: SettingsKeys.appAppearance) as? Int,
           let theme = Theme(legacyIndex: legacy) {
            defaults.set(theme.rawValue, forKey: SettingsKeys.appAppearance)
            return theme
        }
        // Default if nothing set
        return .system
    }
    
    /// Apply theme on scene/window creation (SceneDelegate).
    func applyInitialTheme(for window: UIWindow?) {
        apply(theme: Self.currentTheme(), to: window)
    }
    
    /// Convenience for screens that update the theme live.
    static func applyTheme() {
        let theme = currentTheme()
        
        // Always hop to main for UI work
        DispatchQueue.main.async {
            // Apply to every window in every connected scene (multi-window, external display, etc.)
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    apply(theme: theme, to: window)
                }
            }
            
            // Fallback: if for some reason there are no scenes yet, try key window
            if UIApplication.shared.connectedScenes.isEmpty {
                let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
                apply(theme: theme, to: keyWindow)
            }
        }
    }
    
    private static func apply(theme: Theme, to window: UIWindow?) {
        switch theme {
        case .light:  window?.overrideUserInterfaceStyle = .light
        case .dark:   window?.overrideUserInterfaceStyle = .dark
        case .system: window?.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    // Instance wrapper for SceneDelegate usage
    private func apply(theme: Theme, to window: UIWindow?) {
        Self.apply(theme: theme, to: window)
    }
}

