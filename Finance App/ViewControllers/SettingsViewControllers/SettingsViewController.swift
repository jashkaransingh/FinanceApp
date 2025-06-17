//
//  SettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/28/25.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    // MARK: – Sections
    private enum Section: Int, CaseIterable {
        case account, preferences, about
        var title: String {
            switch self {
            case .account:     return "Account"
            case .preferences: return "Preferences"
            case .about:       return "About"
            }
        }
    }
    
    // MARK: – UI Elements
    /// Button to trigger a test notification.
    private let triggerNotifButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Trigger Test Notification", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        configureTableView()
        configureFooterView()
        
        configureTriggerButton()
        
    }
    
    // MARK: – UI Configuration
    
    /// Sets up the table’s style and registers cells.
    private func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
    }
    
    private func configureFooterView() {
        let footer = UIView(frame: .init(x: 0, y: 0, width: view.bounds.width, height: 80))
        footer.backgroundColor = .clear
        
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(card)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: footer.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -16)
        ])
        
        let signOutBtn = makeSignOutButton()
        card.addSubview(signOutBtn)
        NSLayoutConstraint.activate([
            signOutBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            signOutBtn.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        
        tableView.tableFooterView = footer
    }
    
    /// Creates the red “Sign Out” button.
    private func makeSignOutButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("Sign Out", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
    
    
    private func configureTriggerButton() {/// Places the “Trigger Test Notification” button at bottom of view.
        view.addSubview(triggerNotifButton)
        NSLayoutConstraint.activate([
            triggerNotifButton.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            triggerNotifButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -32)
        ])
        triggerNotifButton.addTarget(self,
                                     action: #selector(didTapTriggerNotification),
                                     for: .touchUpInside)
    }
    
    
    
    // MARK: – Table DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }
    
    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .account:     return 1      // Linked Accounts
        case .preferences: return 2      // Notifications, Dark Mode
        case .about:       return 2      // Version, Help & Feedback
        }
    }
    
    override func tableView(
        _ tv: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        
        // Version cell in About section
        if section == .about && indexPath.row == 0 {
            return makeVersionCell()
        }
        
        let cell = tv.dequeueReusableCell(
            withIdentifier: "DefaultCell",
            for: indexPath
        )
        cell.accessoryView = nil
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        
        switch (section, indexPath.row) {
        case (.account, 0):
            cell.textLabel?.text = "Linked Accounts"
            
        case (.preferences, 0):
            cell.textLabel?.text = "Notifications"
            
        case (.preferences, 1):
            cell.textLabel?.text = "Dark Mode"
            let toggle = makeDarkModeToggle()
            cell.accessoryView = toggle
            cell.accessoryType = .none
            
        case (.about, 1):
            cell.textLabel?.text = "Help & Feedback"
            
        default:
            break
        }
        
        return cell
    }
    
    /// Creates the Version cell (non-selectable).
    private func makeVersionCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = "Version"
        cell.detailTextLabel?.text = Bundle.main
            .infoDictionary?["CFBundleShortVersionString"] as? String
        cell.selectionStyle = .none
        return cell
    }
    
    /// Creates the Dark Mode UISwitch.
    private func makeDarkModeToggle() -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        toggle.addTarget(self, action: #selector(didToggleDarkMode(_:)), for: .valueChanged)
        return toggle
    }
    
    // MARK: – Delegate
    
    override func tableView(_ tv: UITableView,
                            didSelectRowAt ip: IndexPath)
    {
        tv.deselectRow(at: ip, animated: true)
        let section = Section(rawValue: ip.section)!
        
        switch (section, ip.row) {
        case (.account, 0):
            let vc = LinkedAccountsViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case (.preferences, 0):
            let vc = NotificationsSettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case (.about, 1):
            let vc = HelpFeedbackViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        default:
            break   // Version row and Dark Mode toggle are not “push” actions
        }
    }
    
    // MARK: – Actions
    
    @objc private func didToggleDarkMode(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn,
                                  forKey: "darkModeEnabled")
        // apply globally immediately
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first
        {
            scene.windows.first?.overrideUserInterfaceStyle =
            sender.isOn ? .dark : .light
        }
    }
    
    @objc private func signOutTapped() {
        let alert = UIAlertController(
            title: "Sign Out?",
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Sign Out", style: .destructive) { _ in
            AuthService.signOut()
            SceneDelegate.switchToLogin()
        })
        present(alert, animated: true)
    }
    @objc private func didTapTriggerNotification() {
        // fire a notification 10 seconds from now
        NotificationService.shared.scheduleSummaryNotification(after: 10)
    }
}




