//
//  ThemeManager.swift
//  Finance App
//
//  Created by Jas  on 7/30/25.
//

import UIKit

class ThemeManager {
    
    // A shared instance for easy access
    static let shared = ThemeManager()
    
    // Enum to represent the different theme options
    enum Theme: Int {
        case system, light, dark
    }
    
    // The key to save the user's choice in UserDefaults
     let themeKey = "appAppearance"

    /// Applies the saved theme to the entire application window.
    func applyInitialTheme(for window: UIWindow?) {
        let savedTheme = UserDefaults.standard.integer(forKey: themeKey)
        guard let theme = Theme(rawValue: savedTheme) else { return }
        
        switch theme {
        case .light:
            window?.overrideUserInterfaceStyle = .light
        case .dark:
            window?.overrideUserInterfaceStyle = .dark
        case .system:
            // .unspecified tells the app to follow the system setting
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    /// A static version for convenience, used by the Appearance screen.
    static func applyTheme() {
        let savedTheme = UserDefaults.standard.integer(forKey: shared.themeKey)
        guard let theme = Theme(rawValue: savedTheme) else { return }
        
        // Get the main app window to apply the theme
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        switch theme {
        case .light:
            window?.overrideUserInterfaceStyle = .light
        case .dark:
            window?.overrideUserInterfaceStyle = .dark
        case .system:
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }
}
