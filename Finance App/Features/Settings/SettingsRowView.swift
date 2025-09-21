//
//  SettingsRowView.swift
//  Finance App
//
//  Created by Jas  on 8/5/25.
//

import UIKit

/// A reusable, configurable view that represents a single row within a settings card.
final class SettingsRowView: UIControl {
    
    enum AccessoryType {
        case chevron
        case aSwitch(isOn: Bool, action: (Bool) -> Void)
        case detail(String)
        case centeredDestructive
        case none
    }
    
    // MARK: - UI Properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    
    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let accessorySwitch: UISwitch = {
        let aSwitch = UISwitch()
        aSwitch.isHidden = true
        aSwitch.translatesAutoresizingMaskIntoConstraints = false
        return aSwitch
    }()
    
    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    private let trailingContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let highlightOverlay: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        v.alpha = 0
        v.layer.cornerRadius = 12 // soft round so it reads as a “sheen”
        return v
    }()
    
    private let hStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .fill        // default; we’ll change to .equalCentering for destructive
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isUserInteractionEnabled = false
        return sv
    }()
    
    
    
    private var switchAction: ((Bool) -> Void)?
    private var rowHeightConstraint: NSLayoutConstraint?
    
    
    override var isHighlighted: Bool {
        didSet {
            guard accessorySwitch.isHidden else { return } // don’t animate switch rows
            let pressed = isHighlighted
            UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = pressed ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.highlightOverlay.alpha = pressed ? 1 : 0
            }
        }
    }
    
    
    // MARK: - Init
    
    init(icon: UIImage?, iconBackgroundColor: UIColor, title: String, accessoryType: AccessoryType = .chevron) {
        super.init(frame: .zero)
        
        // Configure views with initial data
        iconImageView.image = icon?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        iconImageView.tintColor = .white
        iconContainerView.backgroundColor = iconBackgroundColor
        titleLabel.text = title
        
        setupViews()
        configure(with: accessoryType)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .clear
        
        iconContainerView.addSubview(iconImageView)
        
        hStack.addArrangedSubview(iconContainerView)
        hStack.addArrangedSubview(titleLabel)
        hStack.addArrangedSubview(trailingContainer)
        
        iconContainerView.isUserInteractionEnabled = false
        titleLabel.isUserInteractionEnabled = false
        
        addSubview(highlightOverlay)
        highlightOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)
        
        rowHeightConstraint = heightAnchor.constraint(equalToConstant: Design.Row.height)
        rowHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            iconContainerView.widthAnchor.constraint(equalToConstant: 30),
            iconContainerView.heightAnchor.constraint(equalToConstant: 30),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            
            trailingContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            // Replace stackView constraints with hStack
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            highlightOverlay.topAnchor.constraint(equalTo: topAnchor),
            highlightOverlay.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            highlightOverlay.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            highlightOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        trailingContainer.addSubview(accessoryImageView)
        trailingContainer.addSubview(accessorySwitch)
        trailingContainer.addSubview(detailLabel)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        accessorySwitch.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            accessoryImageView.centerYAnchor.constraint(equalTo: trailingContainer.centerYAnchor),
            accessoryImageView.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor),
            
            accessorySwitch.centerYAnchor.constraint(equalTo: trailingContainer.centerYAnchor),
            accessorySwitch.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor),
            
            detailLabel.centerYAnchor.constraint(equalTo: trailingContainer.centerYAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor)
        ])
    }
    
    private func configure(with accessoryType: AccessoryType) {
        // Reset visibility
        accessoryImageView.isHidden = true
        accessorySwitch.isHidden = true
        detailLabel.isHidden = true
        iconContainerView.isHidden = false
        trailingContainer.isHidden = false
        titleLabel.textAlignment = .natural
        hStack.distribution = .fill
        
        switch accessoryType {
        case .chevron:
            accessoryImageView.isHidden = false
            
        case .aSwitch(let isOn, let action):
            accessorySwitch.isHidden = false
            accessorySwitch.isOn = isOn
            accessorySwitch.isUserInteractionEnabled = true
            // avoid duplicate targets when reused
            accessorySwitch.removeTarget(self, action: #selector(onSwitchValueChanged), for: .valueChanged)
            self.switchAction = action
            accessorySwitch.addTarget(self, action: #selector(onSwitchValueChanged), for: .valueChanged)
            
        case .detail(let text):
            detailLabel.text = text
            detailLabel.isHidden = false
            
        case .centeredDestructive:
            // Hide chrome
            iconContainerView.isHidden = true
            trailingContainer.isHidden = true
            
            // Center the only remaining arranged subview by using the stack’s distribution
            hStack.distribution = .equalCentering
            titleLabel.textAlignment = .center
            titleLabel.textColor = .systemRed
        case .none:
            break
        }
    }
    
    public func setTextColor(_ color: UIColor) {
        titleLabel.textColor = color
    }
    
    @objc private func onSwitchValueChanged(_ sender: UISwitch) {
        switchAction?(sender.isOn)
    }
    // Allow the VC to flip the switch without poking internals or firing actions unintentionally.
    public func setSwitch(isOn: Bool, animated: Bool, sendEvent: Bool = false) {
        guard accessorySwitch.isHidden == false else { return }
        accessorySwitch.setOn(isOn, animated: animated)
        if sendEvent {
            accessorySwitch.sendActions(for: .valueChanged)
        }
    }
}
