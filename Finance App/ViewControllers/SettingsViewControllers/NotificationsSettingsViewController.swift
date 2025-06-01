//
//  NotificationsSettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//

import UIKit

final class NotificationsSettingsViewController: UITableViewController {
  
  // MARK: – Notification Options

  private enum Option: Int, CaseIterable {
    case dailySummary
    case weeklySummary
    case weekendAlerts

    /// The title that appears in the cell
    var title: String {
      switch self {
      case .dailySummary:  return "Daily Summary"
      case .weeklySummary: return "Weekly Summary"
      case .weekendAlerts: return "Weekend Alerts"
      }
    }

    /// Key for UserDefaults
    var userDefaultsKey: String {
      switch self {
      case .dailySummary:  return "notifications_dailySummary"
      case .weeklySummary: return "notifications_weeklySummary"
      case .weekendAlerts: return "notifications_weekendAlerts"
      }
    }
  }
  
  // MARK: – Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Notifications"
    configureTableView()
  }

  // MARK: – Setup

  private func configureTableView() {
    tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.register(UITableViewCell.self,
                       forCellReuseIdentifier: "NotificationCell")
  }

  // MARK: – Data Source

  override func numberOfSections(in tableView: UITableView) -> Int {
    1  // only one section of toggles
  }

  override func tableView(_ tv: UITableView,
                          numberOfRowsInSection section: Int) -> Int
  {
    Option.allCases.count
  }

  override func tableView(_ tv: UITableView,
                          cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let cell = tv.dequeueReusableCell(
      withIdentifier: "NotificationCell",
      for: indexPath
    )

    let opt = Option(rawValue: indexPath.row)!
    cell.textLabel?.text = opt.title
    cell.selectionStyle = .none

    // build the switch
    let toggle = UISwitch()
    toggle.isOn = UserDefaults.standard.bool(forKey: opt.userDefaultsKey)
    toggle.tag = opt.rawValue
    toggle.addTarget(self,
                     action: #selector(didToggleOption(_:)),
                     for: .valueChanged)

    cell.accessoryView = toggle
    return cell
  }

  // MARK: – Actions

  @objc private func didToggleOption(_ sender: UISwitch) {
    guard let opt = Option(rawValue: sender.tag) else { return }

    // 1) persist the new value
    UserDefaults.standard.set(sender.isOn, forKey: opt.userDefaultsKey)

    // 2) schedule or cancel your local notifications
    //    (insert your actual scheduling code here)
    switch opt {
    case .dailySummary:
      if sender.isOn {
        // scheduleDailySummaryNotification()
      } else {
        // cancelDailySummaryNotification()
      }

    case .weeklySummary:
      if sender.isOn {
        // scheduleWeeklySummaryNotification()
      } else {
        // cancelWeeklySummaryNotification()
      }

    case .weekendAlerts:
      if sender.isOn {
        // scheduleWeekendAlerts()
      } else {
        // cancelWeekendAlerts()
      }
    }
  }
}

