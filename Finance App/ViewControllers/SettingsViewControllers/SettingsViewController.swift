//
//  SettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/28/25.
//

import UIKit
import LocalAuthentication
import FirebaseAuth

class SettingsViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var sections = [SettingsSection: [SettingsRow]]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        configureDataSource()
        configureTableView()
    }
    
    // MARK: - Configuration
    
    private func configureTableView() {
        // Register the custom cell
        tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)
    }
    
    override init(style: UITableView.Style) {
        // Set the desired style for the UITableViewController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Populates the data source that drives the table view.
    private func configureDataSource() {
        let userEmail = Auth.auth().currentUser?.email ?? "Your Account"
        
        sections[.account] = [
            SettingsRow(type: .info, title: userEmail, icon: UIImage(systemName: "person.crop.circle"), iconBackgroundColor: .systemGray, detailText: nil),
            SettingsRow(type: .standard, title: "Change Password", icon: UIImage(systemName: "key.fill"), iconBackgroundColor: .systemBlue, action: { [weak self] in
                self?.navigate(to: ChangePasswordViewController())
            }),
            SettingsRow(type: .standard, title: "Linked Accounts", icon: UIImage(systemName: "link"), iconBackgroundColor: .systemBlue, action: { [weak self] in
                self?.navigate(to: LinkedAccountsViewController())
            }),
            SettingsRow(type: .standard, title: "Delete Account", icon: UIImage(systemName: "trash.fill"), iconBackgroundColor: .systemRed, action: { [weak self] in
                self?.navigate(to: DeleteAccountViewController())
            })
        ]
        
        sections[.preferences] = [
            SettingsRow(type: .withSwitch, title: "App Lock", icon: UIImage(systemName: "faceid"), iconBackgroundColor: .systemGreen, action: { [weak self] in
                self?.handleAppLockToggle()
            }, userDefaultsKey: "isAppLockEnabled"),
            SettingsRow(type: .standard, title: "Notifications", icon: UIImage(systemName: "bell.badge.fill"), iconBackgroundColor: .systemRed, action: { [weak self] in
                self?.navigate(to: NotificationsSettingsViewController(style: .insetGrouped))
            }),
            SettingsRow(type: .withSwitch, title: "Dark Mode", icon: UIImage(systemName: "moon.fill"), iconBackgroundColor: .systemIndigo, action: { [weak self] in
                self?.handleDarkModeToggle()
            }, userDefaultsKey: "isDarkModeManuallySet")
        ]
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        sections[.about] = [
            SettingsRow(type: .info, title: "Version", icon: UIImage(systemName: "info.circle.fill"), iconBackgroundColor: .systemTeal, detailText: version),
            SettingsRow(type: .standard, title: "Terms of Service", icon: UIImage(systemName: "doc.text.fill"), iconBackgroundColor: .systemGray, action: {
                // Present a web view
            }),
            SettingsRow(type: .standard, title: "Privacy Policy", icon: UIImage(systemName: "hand.raised.fill"), iconBackgroundColor: .systemGray, action: {
                // Present a web view
            })
        ]
        
        sections[.signOut] = [
            SettingsRow(type: .destructive, title: "Sign Out", icon: nil, iconBackgroundColor: .clear, action: { [weak self] in
                self?.signOutTapped()
            })
        ]
    }
    
    // MARK: - Actions
    
    private func handleAppLockToggle() {
        let isEnabled = UserDefaults.standard.bool(forKey: "isAppLockEnabled")
        if !isEnabled { return } // Only prompt when turning it ON
        
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            // Device doesn't support biometrics. Show an alert.
            showAlert(title: "Unsupported", message: "This device does not support Face ID or Touch ID.")
            UserDefaults.standard.set(false, forKey: "isAppLockEnabled")
            tableView.reloadData()
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to enable App Lock.") { [weak self] success, _ in
            DispatchQueue.main.async {
                if !success {
                    UserDefaults.standard.set(false, forKey: "isAppLockEnabled")
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func handleDarkModeToggle() {
        // The SettingsCell's switch should be responsible for saving the new value
        // to UserDefaults using the "isDarkModeManuallySet" key.
        
        // This action closure then just reads that new value and applies the theme.
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkModeManuallySet")
        view.window?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }
    
    private func signOutTapped() {
        let alert = UIAlertController(title: "Sign Out?", message: "You will be returned to the login screen.", preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Sign Out", style: .destructive) { _ in
            // Use your existing sign out logic
            AuthService.signOut()
            SceneDelegate.switchToLogin()
            print("Signing out...")
        })
        present(alert, animated: true)
    }
    
    private func navigate(to viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension SettingsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = SettingsSection(rawValue: section) else { return 0 }
        return sections[sectionType]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsSection(rawValue: section)?.title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseIdentifier, for: indexPath) as? SettingsCell else {
            fatalError("Could not dequeue SettingsCell")
        }
        guard let sectionType = SettingsSection(rawValue: indexPath.section),
              let rowModel = sections[sectionType]?[indexPath.row] else {
            return cell
        }
        
        cell.configure(with: rowModel)
        if rowModel.type == .destructive {
            cell.textLabel?.textAlignment = .center
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sectionType = SettingsSection(rawValue: indexPath.section),
              let rowModel = sections[sectionType]?[indexPath.row] else {
            return
        }
        
        // Execute the action associated with the row
        rowModel.action?()
    }
}




