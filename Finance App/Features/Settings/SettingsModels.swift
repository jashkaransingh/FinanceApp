//
//  SettingsModels.swift
//  Finance App
//
//  Created by Jas  on 6/30/25.
//

import UIKit

// Defines the sections of the settings screen
enum SettingsSection: Int, CaseIterable, Hashable {
    case account
    case preferences
    case about
    case signOut // A dedicated section for the sign out button

    var title: String? { // Make title optional for sections without one
        switch self {
        case .account:
            return "Account"
        case .preferences:
            return "Preferences"
        case .about:
            return "About"
        case .signOut:
            return nil // The sign out button doesn't need a section title
        }
    }
}

// A more descriptive enum for the type of row
enum SettingsRowType {
    case standard // A plain cell, usually for navigation
    case withSwitch // A cell with a UISwitch
    case destructive // A cell for a destructive action, like signing out
    case info // A cell to display non-interactive information (like version)
}

// The enhanced model for a single row
struct SettingsRow {
    let type: SettingsRowType
    let title: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    var detailText: String? = nil // For things like the app version
    var action: (() -> Void)? = nil
    var userDefaultsKey: String? = nil // To manage the state of switches

    init(type: SettingsRowType, title: String, icon: UIImage?, iconBackgroundColor: UIColor, detailText: String? = nil, action: (() -> Void)? = nil, userDefaultsKey: String? = nil) {
        self.type = type
        self.title = title
        self.icon = icon
        self.iconBackgroundColor = iconBackgroundColor
        self.detailText = detailText
        self.action = action
        self.userDefaultsKey = userDefaultsKey
    }
}
