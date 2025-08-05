//
//  TitleHeaderView.swift
//  Finance App
//
//  Created by Jas  on 5/29/25.
//

import UIKit

/// A standalone header with a big title + chevron + profile button,
/// exposes a closure for the profile‐tap action.
class TitleHeaderView: UIView {
    
    // MARK: - Public API
    
    /// Called when the user taps the profile icon
    var onProfileTap: (() -> Void)?
    
    
    // MARK: - Subviews
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "My Accounts"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.adjustsFontSizeToFitWidth = true // Allows the font to shrink
        label.minimumScaleFactor = 0.7
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    public var title: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
      }
    
    private let profileButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let img = UIImage(systemName: "person.crop.circle", withConfiguration: cfg)
        btn.setImage(img, for: .normal)
        btn.tintColor = .secondaryLabel
        return btn
    }()
    
    private lazy var titleStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel]) // Only the label is needed
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 4
        return s
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - Setup
    
    private func setupViews() {
        addSubview(titleStack)
        addSubview(profileButton)
        profileButton.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // pin the stack to the left & full vertical
            titleStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleStack.topAnchor.constraint(equalTo: topAnchor),
            titleStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // pin the profile icon to the right, centered on the stack
            profileButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileButton.centerYAnchor.constraint(equalTo: titleStack.centerYAnchor),
            
            titleStack.trailingAnchor.constraint(lessThanOrEqualTo: profileButton.leadingAnchor, constant: -8)
        ])
    }
    
    
    // MARK: - Actions
    
    @objc private func handleProfileTap() {
        onProfileTap?()
    }
    
}


