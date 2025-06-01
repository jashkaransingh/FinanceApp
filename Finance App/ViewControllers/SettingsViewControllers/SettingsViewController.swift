//
//  SettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/28/25.
//

import UIKit

class SettingsViewController: UITableViewController {
  
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
  
  // MARK: – Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Settings"
    configureTableView()
    configureFooterView()
  }

  // MARK: – Setup Helpers

  private func configureTableView() {
    tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.register(UITableViewCell.self,
                       forCellReuseIdentifier: "DefaultCell")
  }

  private func configureFooterView() {
    // A transparent container for our little “card”
    let footerHeight: CGFloat = 80
    let footer = UIView(frame: CGRect(
      x: 0, y: 0,
      width: tableView.bounds.width,
      height: footerHeight
    ))
    footer.backgroundColor = .clear

    // The white/secondary-system-grouped card
    let card = UIView()
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    footer.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: footer.topAnchor, constant: 16),
      card.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16),
      card.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
      card.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -16),
    ])

    // The red “Sign Out” button centered in that card
    let button = UIButton(type: .system)
    button.setTitle("Sign Out", for: .normal)
    button.setTitleColor(.red, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    button.addTarget(self,
                     action: #selector(signOutTapped),
                     for: .touchUpInside)
    card.addSubview(button)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      button.centerYAnchor.constraint(equalTo: card.centerYAnchor)
    ])

    tableView.tableFooterView = footer
  }

  // MARK: – Data Source

  override func numberOfSections(in tableView: UITableView) -> Int {
    Section.allCases.count
  }

  override func tableView(_ tv: UITableView,
                          titleForHeaderInSection section: Int) -> String?
  {
    Section(rawValue: section)?.title
  }

  override func tableView(_ tv: UITableView,
                          numberOfRowsInSection section: Int) -> Int
  {
    switch Section(rawValue: section)! {
    case .account:     return 1     // Linked Accounts
    case .preferences: return 2     // Notifications + Dark Mode
    case .about:       return 2     // Version + Help & Feedback
    }
  }

  override func tableView(_ tv: UITableView,
                          cellForRowAt ip: IndexPath) -> UITableViewCell
  {
    let section = Section(rawValue: ip.section)!
    
    // — Inline “Version” cell with detailTextLabel
    if section == .about && ip.row == 0 {
      let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
      cell.textLabel?.text = "Version"
      cell.detailTextLabel?.text = Bundle.main
        .infoDictionary?["CFBundleShortVersionString"] as? String
      cell.selectionStyle = .none
      return cell
    }

    // All other rows use our default cell
    let cell = tv.dequeueReusableCell(
      withIdentifier: "DefaultCell", for: ip
    )
    cell.accessoryView = nil
    cell.accessoryType = .disclosureIndicator
    cell.selectionStyle = .default

    switch (section, ip.row) {
    // Account
    case (.account, 0):
      cell.textLabel?.text = "Linked Accounts"

    // Preferences
    case (.preferences, 0):
      cell.textLabel?.text = "Notifications"

    case (.preferences, 1):
      cell.textLabel?.text = "Dark Mode"
      let toggle = UISwitch()
      toggle.isOn = UserDefaults.standard.bool(
        forKey: "darkModeEnabled"
      )
      toggle.addTarget(self,
                       action: #selector(didToggleDarkMode(_:)),
                       for: .valueChanged)
      cell.accessoryView = toggle
      cell.accessoryType = .none

    // About
    case (.about, 1):
      cell.textLabel?.text = "Help & Feedback"

    default:
      break
    }

    return cell
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
}




