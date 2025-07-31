//
//  AuthTextField.swift
//  Finance App
//
//  Created by Jas  on 7/6/25.
//

import UIKit

class AuthTextField: UIView {

    let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .secondaryLabel
        return iv
    }()

    let textField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = .label
        return tf
    }()
    
    private lazy var visibilityToggleButton: UIButton = {
            let button = UIButton(type: .system)
            button.tintColor = .secondaryLabel
            // Set the initial image to the 'eye' icon
            button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.accessibilityIdentifier = "passwordVisibilityToggle" 
            button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
            return button
        }()

    init(icon: UIImage?, isSecure: Bool = false) {
        super.init(frame: .zero)
        iconImageView.image = icon
        textField.keyboardType = isSecure
            ? .default
            : .emailAddress      // for non-secure we’ll assume email by default

        textField.autocapitalizationType = .none
        textField.autocorrectionType     = .no
        textField.isSecureTextEntry = isSecure
        iconImageView.isAccessibilityElement = false
        textField.isAccessibilityElement = true
        
        if isSecure {
                    textField.rightView = visibilityToggleButton
                    textField.rightViewMode = .always
                }

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func togglePasswordVisibility() {
            // Toggle the secure text entry state
            textField.isSecureTextEntry.toggle()
            
            // Change the icon based on the new state
            let imageName = textField.isSecureTextEntry ? "eye.fill" : "eye.slash.fill"
            visibilityToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
        }

    private func setupView() {
        backgroundColor = .clear

        let bottomLine = UIView()
        bottomLine.backgroundColor = .separator
        addSubview(bottomLine)
        bottomLine.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [iconImageView, textField])
        stackView.spacing = 10
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 22),

            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),

            bottomLine.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            bottomLine.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    var iconTintColor: UIColor? {
      get { iconImageView.tintColor }
      set { iconImageView.tintColor = newValue }
    }
}
