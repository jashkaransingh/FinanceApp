//
//  AppearanceSettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 8/19/25.
//

import UIKit

class AppearanceSettingsViewController: UITableViewController {
    
    // Include the theme in the model so rows aren’t tied to indices
    private let options: [(theme: ThemeManager.Theme, title: String, icon: String)] = [
        (.system, "System", "gearshape.fill"),
        (.light,  "Light",  "sun.max.fill"),
        (.dark,   "Dark",   "moon.fill")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Appearance"
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
        options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AppearanceCell.reuseIdentifier,
            for: indexPath
        ) as? AppearanceCell else {
            fatalError("Could not dequeue AppearanceCell")
        }
        
        let option = options[indexPath.row]
        cell.configure(title: option.title, iconName: option.icon)
        
        // Read current theme (handles migration automatically)
        let selected = ThemeManager.currentTheme()
        cell.accessoryType = (option.theme == selected) ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let chosen = options[indexPath.row].theme
        // Persist enum rawValue (string) via centralized key
        UserDefaults.standard.set(chosen.rawValue, forKey: SettingsKeys.appAppearance)
        
        ThemeManager.applyTheme()
        tableView.reloadData()
    }
}
