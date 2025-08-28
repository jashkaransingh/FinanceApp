//
//  AppearanceSettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 8/19/25.
//

import UIKit

class AppearanceSettingsViewController: UITableViewController {
    
    // We'll store our options as a tuple to include the icon name
    private let options: [(title: String, icon: String)] = [
        ("System", "gearshape.fill"),
        ("Light", "sun.max.fill"),
        ("Dark", "moon.fill")
    ]
    
    private let themeKey = "appAppearance" // Using the correct key
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Appearance"
        // Register our new custom cell
        tableView.register(AppearanceCell.self, forCellReuseIdentifier: AppearanceCell.reuseIdentifier)
    }

    override init(style: UITableView.Style) {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - TableView DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AppearanceCell.reuseIdentifier, for: indexPath) as? AppearanceCell else {
            fatalError("Could not dequeue AppearanceCell")
        }
        
        let option = options[indexPath.row]
        cell.configure(title: option.title, iconName: option.icon)
        
        // Add a checkmark to the currently selected theme
        let selectedTheme = UserDefaults.standard.integer(forKey: themeKey)
        cell.accessoryType = (indexPath.row == selectedTheme) ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        UserDefaults.standard.set(indexPath.row, forKey: themeKey)
        ThemeManager.applyTheme()
        tableView.reloadData()
    }
}


