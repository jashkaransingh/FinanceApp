//
//  NotificationsSettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//

import UIKit

// MARK: - Delegate Protocols
protocol ToggleCellDelegate: AnyObject {
    func didToggleSwitch(for type: NotificationType, isOn: Bool)
}

protocol TimePickerCellDelegate: AnyObject {
    func didChangeTime(for type: NotificationType, newTime: DateComponents)
}

// MARK: - NotificationsSettingsViewController
final class NotificationsSettingsViewController: UITableViewController {
    
    // MARK: - Section & Row Models
    private struct Section {
        let title: String?
        var rows: [Row]
    }
    
    enum Row {
        case toggle(icon: String, title: String, subtitle: String, type: NotificationType)
        case timePicker(type: NotificationType)
    }
    
    private var sections: [Section] = []
    
    // MARK: - Lifecycle & Setup
    override init(style: UITableView.Style) {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        configureTableView()
        buildSections()
    }
    
    private func configureTableView() {
        tableView.register(ToggleCell.self, forCellReuseIdentifier: "ToggleCell")
        tableView.register(TimePickerCell.self, forCellReuseIdentifier: "TimePickerCell")
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func buildSections() {
        let dailySummaryPlaceholder = NotificationType.dailySummary(context: .init(spentYesterday: 0, spentDayBefore: 0))
        let dailySummaryEnabled = UserDefaults.standard.bool(forKey: NotificationSetting.dailySummary.key)
        
        var summaryRows: [Row] = [
            .toggle(icon: "calendar.day.timeline.left", title: "Daily Summary", subtitle: "A look at yesterday's spending.", type: dailySummaryPlaceholder),
        ]
        
        if dailySummaryEnabled {
            summaryRows.append(.timePicker(type: dailySummaryPlaceholder))
        }
        
        sections = [
            Section(title: "SUMMARIES", rows: summaryRows),
            Section(title: "ALERTS", rows: [
                .toggle(icon: "exclamationmark.triangle", title: "Budget Alerts", subtitle: "Get notified when you're near a spending limit.", type: .budgetNearLimit(context: .init(category: "", percent: nil))),
                .toggle(icon: "sparkles", title: "Weekend Alerts", subtitle: "A friendly reminder on Saturday & Sunday.", type: .weekendAlert)
            ])
        ]
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int { return sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return sections[section].rows.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return sections[section].title }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row {
        case .toggle(let icon, let title, let subtitle, let type):
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath) as! ToggleCell
            cell.configure(icon: icon, title: title, subtitle: subtitle, type: type)
            cell.delegate = self
            return cell
            
        case .timePicker(let type):
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimePickerCell", for: indexPath) as! TimePickerCell
            cell.configure(for: type)
            cell.delegate = self
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        return row.isToggle ? UITableView.automaticDimension : 160
    }
}

// MARK: - CellDelegate Conformance
extension NotificationsSettingsViewController: ToggleCellDelegate, TimePickerCellDelegate {
    
    func didToggleSwitch(for type: NotificationType, isOn: Bool) {
        guard let setting = type.setting else { return }
        UserDefaults.standard.set(isOn, forKey: setting.key)
        
        if isOn {
            if case .dailySummary = type {
                NotificationService.shared.refreshDailySummaryNotification()
            } else {
                NotificationService.shared.scheduleNotification(for: type)
            }
        } else {
            NotificationService.shared.cancelNotification(for: type)
        }
        
        if case .dailySummary = type {
            self.buildSections()
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    func didChangeTime(for type: NotificationType, newTime: DateComponents) {
        NotificationService.shared.saveTime(for: type, components: newTime)
        
        if case .dailySummary = type {
            NotificationService.shared.refreshDailySummaryNotification(at: newTime)
        }
    }
}

// MARK: - Custom Cells
class ToggleCell: UITableViewCell {
    weak var delegate: ToggleCellDelegate?
    private var type: NotificationType?
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let toggle = UISwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(icon: String, title: String, subtitle: String, type: NotificationType) {
        self.type = type
        iconImageView.image = UIImage(systemName: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        if let setting = type.setting {
            toggle.isOn = UserDefaults.standard.bool(forKey: setting.key)
        }
        selectionStyle = .none
    }
    
    // FIX: Restored the complete UI setup code that was missing.
    private func setupUI() {
        iconImageView.tintColor = .label
        iconImageView.contentMode = .center
        
        titleLabel.font = .systemFont(ofSize: 17)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        toggle.addTarget(self, action: #selector(handleToggle), for: .valueChanged)
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        
        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack, toggle])
        mainStack.axis = .horizontal
        mainStack.spacing = 16
        mainStack.alignment = .center
        
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    @objc private func handleToggle() {
        guard let type = type else { return }
        delegate?.didToggleSwitch(for: type, isOn: toggle.isOn)
    }
}

class TimePickerCell: UITableViewCell {
    weak var delegate: TimePickerCellDelegate?
    private var type: NotificationType?
    
    private let datePicker = UIDatePicker()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(for type: NotificationType) {
        self.type = type
        let components = NotificationService.shared.getStoredTime(for: type)
        datePicker.date = Calendar.current.date(from: components) ?? Date()
    }
    
    // FIX: Restored the complete UI setup code that was missing.
    private func setupUI() {
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(handleTimeChange), for: .valueChanged)
        
        contentView.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: contentView.topAnchor),
            datePicker.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc private func handleTimeChange() {
        guard let type = type else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: datePicker.date)
        delegate?.didChangeTime(for: type, newTime: components)
    }
}

// Helper extension for the Row enum
extension NotificationsSettingsViewController.Row {
    var isToggle: Bool {
        if case .toggle = self { return true }
        return false
    }
}



