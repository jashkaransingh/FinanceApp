//
//  SettingsStore.swift
//  Finance App
//
//  Created by Jas  on 8/26/25.
//

import Foundation

enum SettingsKeys {
    static let isAppLockEnabled = "isAppLockEnabled"
    static let appAppearance    = "appAppearance"
}

enum SettingsStore {
    static var isAppLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: SettingsKeys.isAppLockEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKeys.isAppLockEnabled) }
    }
}
