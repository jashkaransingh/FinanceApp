//
//  ThemeManager.swift
//  Finance App
//
//  Created by Jas  on 7/30/25.
//

import UIKit

final class ThemeManager {
    // 1. Create a shared instance so we can access it from anywhere.
    static let shared = ThemeManager()
    
    // 2. Keep the UserDefaults keys private to this class.
    private let themeHasBeenSetKey = "userHasManuallySetTheme"
    private let isDarkModeKey = "isDarkModeManuallySet"
    
    // 3. A private initializer prevents other parts of the app from creating a new instance.
    private init() {}
    
    // 4. This method moves the logic from your SceneDelegate.
    func applyInitialTheme(for window: UIWindow) {
        // If the user has NEVER set a theme, sync the setting with the system's current style.
        if !UserDefaults.standard.bool(forKey: themeHasBeenSetKey) {
            let isSystemDark = window.traitCollection.userInterfaceStyle == .dark
            UserDefaults.standard.set(isSystemDark, forKey: isDarkModeKey)
        }
        
        // Now apply the theme using the (now correct) stored value.
        let isDarkModeOn = UserDefaults.standard.bool(forKey: isDarkModeKey)
        window.overrideUserInterfaceStyle = isDarkModeOn ? .dark : .light
    }
}
