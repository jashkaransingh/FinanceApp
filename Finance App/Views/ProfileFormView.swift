//
//  FormFieldRowView.swift
//  Finance App
//
//  Created by Jas  on 8/26/25.
//

import UIKit

final class ProfileFormView: UIView {

    // MARK: Public API
    var onChange: (() -> Void)?
    var onChangePassword: (() -> Void)?

    var name: String { nameField.textField.text ?? "" }
    private(set) var email: String = ""

    func configure(name: String, email: String, isEmailVerified: Bool) {
        // Name
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || name.lowercased() == "no name" {
            nameField.textField.text = nil
            nameField.textField.placeholder = "Your name"
        } else {
            nameField.textField.text = name
            nameField.textField.placeholder = "Your name"
        }

        // Email
        self.email = email
        emailLabel.text = email

        // Placeholder status (swap to chip later if you want)
        verifiedIcon.isHidden = !isEmailVerified
        notVerifiedGroup.forEach { $0.isHidden = isEmailVerified }
    }

    func setEditing(_ isEditing: Bool) {
        nameField.textField.isUserInteractionEnabled = isEditing
        if isEditing { nameField.textField.becomeFirstResponder() } else { endEditing(true) }
        nameCapsule.fillColor = isEditing ? .tertiarySystemFill : CapsuleView.neutralFill
    }

    // MARK: - Layout constants
    private let pillHeight: CGFloat = 60
    private let sidePadding: CGFloat = 16
    private let cardPadding: CGFloat = 14
    private let rowSpacing: CGFloat = 25
    private let pillCorner: CGFloat = 20

    // MARK: - Name capsule
    private let nameCapsule = CapsuleView()
    private let nameField: AuthTextField = {
        let v = AuthTextField(icon: UIImage(systemName: "person.fill"), isSecure: false)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.textField.keyboardType = .default
        v.textField.autocapitalizationType = .words
        v.textField.clearButtonMode = .whileEditing
        v.textField.returnKeyType = .done
        v.textField.accessibilityLabel = "Name"
        v.showsBottomLine = false
        return v
    }()

    // MARK: - Email capsule
    private let emailCapsule = CapsuleView()
    private let emailIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "envelope.fill"))
        iv.tintColor = .secondaryLabel
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 20),
            iv.heightAnchor.constraint(equalToConstant: 20)
        ])
        return iv
    }()
    private let emailLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.lineBreakMode = .byTruncatingMiddle
        return l
    }()
    private let verifiedIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.tintColor = .systemGreen
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let notVerifiedDot: UIView = {
        let v = UIView()
        v.backgroundColor = .tertiaryLabel
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 8),
            v.heightAnchor.constraint(equalToConstant: 8)
        ])
        return v
    }()
    private let notVerifiedLabel: UILabel = {
        let l = UILabel()
        l.text = "Not verified"
        l.font = .preferredFont(forTextStyle: .footnote)
        l.textColor = .tertiaryLabel
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()
    private lazy var notVerifiedGroup: [UIView] = [notVerifiedDot, notVerifiedLabel]

    // MARK: - Reset capsule (tappable)
    private let resetCapsule = CapsuleView()
    private let resetControl = UIControl()
    private let resetIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "key.fill"))
        iv.tintColor = .secondaryLabel
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 18),
            iv.heightAnchor.constraint(equalToConstant: 18)
        ])
        return iv
    }()
    private let resetLabel: UILabel = {
        let l = UILabel()
        l.text = "Reset Password"
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        return l
    }()
    private let chevron: UIImageView = {
        let iv = UIImageView(
            image: UIImage(systemName: "chevron.right")?
                .applyingSymbolConfiguration(.init(pointSize: 15, weight: .semibold))
        )
        iv.tintColor = .tertiaryLabel
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let vstack = UIStackView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Build UI
    private func build() {
        vstack.axis = .vertical
        vstack.spacing = rowSpacing
        vstack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vstack)

        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: topAnchor, constant: cardPadding),
            vstack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: cardPadding),
            vstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -cardPadding),
            vstack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -cardPadding)
        ])

        // Style all three capsules
        [nameCapsule, emailCapsule, resetCapsule].forEach { capsule in
            capsule.translatesAutoresizingMaskIntoConstraints = false
            capsule.heightAnchor.constraint(equalToConstant: pillHeight).isActive = true
            capsule.fillColor = CapsuleView.neutralFill
            capsule.strokeColor = CapsuleView.neutralStroke
            capsule.cornerRadiusOverride = pillCorner
        }

        // NAME
        vstack.addArrangedSubview(nameCapsule)
        nameCapsule.addSubview(nameField)
        NSLayoutConstraint.activate([
            nameField.leadingAnchor.constraint(equalTo: nameCapsule.leadingAnchor, constant: sidePadding),
            nameField.trailingAnchor.constraint(equalTo: nameCapsule.trailingAnchor, constant: -sidePadding),
            nameField.centerYAnchor.constraint(equalTo: nameCapsule.centerYAnchor),
            nameField.heightAnchor.constraint(lessThanOrEqualTo: nameCapsule.heightAnchor, constant: -20)
        ])
        nameField.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        // EMAIL
        vstack.addArrangedSubview(emailCapsule)
        let emailRow = UIStackView(arrangedSubviews: [emailIcon, emailLabel, verifiedIcon, notVerifiedDot, notVerifiedLabel])
        emailRow.axis = .horizontal
        emailRow.alignment = .center
        emailRow.spacing = 8
        emailRow.translatesAutoresizingMaskIntoConstraints = false
        emailCapsule.addSubview(emailRow)
        NSLayoutConstraint.activate([
            emailRow.leadingAnchor.constraint(equalTo: emailCapsule.leadingAnchor, constant: sidePadding),
            emailRow.trailingAnchor.constraint(equalTo: emailCapsule.trailingAnchor, constant: -sidePadding),
            emailRow.centerYAnchor.constraint(equalTo: emailCapsule.centerYAnchor)
        ])

        // RESET (tappable)
        vstack.addArrangedSubview(resetCapsule)
        resetCapsule.addSubview(resetControl)
        resetControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetControl.leadingAnchor.constraint(equalTo: resetCapsule.leadingAnchor),
            resetControl.trailingAnchor.constraint(equalTo: resetCapsule.trailingAnchor),
            resetControl.topAnchor.constraint(equalTo: resetCapsule.topAnchor),
            resetControl.bottomAnchor.constraint(equalTo: resetCapsule.bottomAnchor)
        ])

        let resetRow = UIStackView(arrangedSubviews: [resetIcon, resetLabel, chevron])
        resetRow.axis = .horizontal
        resetRow.alignment = .center
        resetRow.spacing = 12
        resetRow.translatesAutoresizingMaskIntoConstraints = false
        resetControl.addSubview(resetRow)
        NSLayoutConstraint.activate([
            resetRow.leadingAnchor.constraint(equalTo: resetControl.leadingAnchor, constant: sidePadding),
            resetRow.trailingAnchor.constraint(equalTo: resetControl.trailingAnchor, constant: -sidePadding),
            resetRow.centerYAnchor.constraint(equalTo: resetControl.centerYAnchor)
        ])

        resetControl.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        resetControl.addTarget(self, action: #selector(highlightDown), for: [.touchDown, .touchDragInside])
        resetControl.addTarget(self, action: #selector(highlightUp),   for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    // MARK: - Actions
    @objc private func textChanged() { onChange?() }
    @objc private func resetTapped() { onChangePassword?() }
    @objc private func highlightDown() { animatePill(resetCapsule, pressed: true) }
    @objc private func highlightUp()   { animatePill(resetCapsule, pressed: false) }

    private func animatePill(_ v: UIView, pressed: Bool) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            v.alpha = pressed ? 0.85 : 1.0
            v.transform = pressed ? CGAffineTransform(scaleX: 0.99, y: 0.99) : .identity
        }
    }
}








