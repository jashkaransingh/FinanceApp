//
//  AuthTextField.swift
//  Finance App
//
//  Created by Jas  on 7/6/25.
//

import UIKit

class AuthTextField: UIView {

    private let iconImageView: UIImageView = {
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

    init(icon: UIImage?, isSecure: Bool = false) {
        super.init(frame: .zero)
        iconImageView.image = icon
        textField.isSecureTextEntry = isSecure
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear

        let bottomLine = UIView()
        bottomLine.backgroundColor = .systemGray5
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
}
