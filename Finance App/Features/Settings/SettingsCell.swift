//
//  SettingsCell.swift
//  Finance App
//
//  Created by Jas  on 7/1/25.
//

import UIKit

class SettingsCell: UITableViewCell {

    static let reuseIdentifier = "SettingsCell"

    // MARK: - UI Components

    private let iconContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        // The action is now handled by the view controller via the model
        toggle.addTarget(self, action: #selector(didToggleSwitch), for: .valueChanged)
        return toggle
    }()

    // MARK: - Properties

    private var rowModel: SettingsRow?
    private var titleLabelCenterXConstraint: NSLayoutConstraint?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clear out previous content to prevent visual bugs
        titleLabel.text = nil
        detailLabel.text = nil
        iconImageView.image = nil
        accessoryView = nil
        accessoryType = .none
        titleLabel.textAlignment = .natural // Reset alignment
        titleLabelCenterXConstraint?.isActive = false
    }

    // MARK: - Configuration

    public func configure(with model: SettingsRow) {
        self.rowModel = model
        
        titleLabel.text = model.title
        iconImageView.image = model.icon
        iconContainerView.backgroundColor = model.iconBackgroundColor
        
        // Show/hide icon based on model
        iconContainerView.isHidden = model.icon == nil
        
        // Configure cell based on its type
        switch model.type {
        case .standard:
            accessoryType = .disclosureIndicator
            selectionStyle = .default
        case .withSwitch:
            if let key = model.userDefaultsKey {
                toggleSwitch.isOn = UserDefaults.standard.bool(forKey: key)
            }
            accessoryView = toggleSwitch
            selectionStyle = .none
        case .destructive:
            titleLabel.textColor = .systemRed
            titleLabel.textAlignment = .center // Center the text
            selectionStyle = .default
            titleLabelCenterXConstraint?.isActive = true
        case .info:
            detailLabel.text = model.detailText
            selectionStyle = .none
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        // We add all views, and then show/hide them in the configure method
        contentView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        titleLabelCenterXConstraint = titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        
        NSLayoutConstraint.activate([
            iconContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainerView.widthAnchor.constraint(equalToConstant: 30),
            iconContainerView.heightAnchor.constraint(equalToConstant: 30),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            // **FIX**: The title label's leading anchor should be conditional
            // For now, we set it and adjust alignment in configure()
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: detailLabel.leadingAnchor, constant: -8),
            
            detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func didToggleSwitch(_ sender: UISwitch) {
        // The action closure from the model will handle the logic
        if let key = rowModel?.userDefaultsKey {
                UserDefaults.standard.set(sender.isOn, forKey: key)
            }
        rowModel?.action?()
    }
}
