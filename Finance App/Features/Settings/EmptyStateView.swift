//
//  EmptyStateView.swift
//  Finance App
//
//  Created by Jas  on 7/1/25.
//

import UIKit

class EmptyStateView: UIView {
    
    // MARK: - UI Components
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No bank account linked."
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Link First Account", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .label
        button.setTitleColor(.systemBackground, for: .normal)
        
        button.layer.cornerRadius = 12
        return button
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        addSubview(messageLabel)
        addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -40),
            
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 40),
            actionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Public Methods
    public func configure(message: String, buttonTitle: String) {
        messageLabel.text = message
        actionButton.setTitle(buttonTitle, for: .normal)
    }
    
    public func setAction(_ target: Any?, action: Selector, for event: UIControl.Event) {
      actionButton.addTarget(target, action: action, for: event)
    }
}
