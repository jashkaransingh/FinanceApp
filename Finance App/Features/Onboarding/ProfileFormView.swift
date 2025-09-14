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
        updateClearVisibility()
    }

    func setEditing(_ isEditing: Bool) {
        nameField.textField.isUserInteractionEnabled = isEditing
        if isEditing { nameField.textField.becomeFirstResponder() } else { endEditing(true) }
        nameCapsule.fillColor = isEditing ? .tertiarySystemFill : CapsuleView.neutralFill
        updateClearVisibility()
    }

    // MARK: - Layout constants
    private let pillHeight: CGFloat = 56
    private let sidePadding: CGFloat = 16
    private let cardPadding: CGFloat = 14
    private let rowSpacing: CGFloat = 12

    // MARK: - Name capsule
    private let nameCapsule = CapsuleView()
    private let nameField: AuthTextField = {
        let v = AuthTextField(icon: UIImage(systemName: "person.fill"), isSecure: false)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.textField.keyboardType = .default
        v.textField.autocapitalizationType = .words
        v.textField.returnKeyType = .done
        v.textField.accessibilityLabel = "Name"
        v.showsBottomLine = false
        return v
    }()
    private let nameClearButton: UIButton = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = .tertiaryLabel
        b.isHidden = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()


    // MARK: - Email capsule
    private let emailCapsule = CapsuleView()
    
    private let emailIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "envelope.fill"))
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
        iv.tintColor = .secondaryLabel
        iv.contentMode = .center
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
        let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: cfg))
        iv.tintColor = .systemGreen
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 20),
            iv.heightAnchor.constraint(equalToConstant: 20)
        ])
        return iv
    }()


    // MARK: - Reset capsule (tappable)
    private let resetCapsule = CapsuleView()
    private let resetControl = UIControl()
    
    private let resetIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "key.fill"))
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
        iv.tintColor = .secondaryLabel
        iv.contentMode = .center
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 20),
            iv.heightAnchor.constraint(equalToConstant: 20)
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
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .center
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 20),
            iv.heightAnchor.constraint(equalToConstant: 20)
        ])
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
            capsule.strokeColor = Design.Hairline.color         // subtle edge
                capsule.lineWidth = Design.Hairline.width           // 1px, not 2px
                capsule.cornerRadiusOverride = Design.Radius.row
        }

        // NAME
        vstack.addArrangedSubview(nameCapsule)
        nameCapsule.addSubview(nameField)

        // Important: disable the system clear (it sits “inside” and won’t align)
        nameField.textField.clearButtonMode = .never

        // Add our own clear button aligned to the same trailing grid as other rows
        nameCapsule.addSubview(nameClearButton)
        NSLayoutConstraint.activate([
            nameField.leadingAnchor.constraint(equalTo: nameCapsule.leadingAnchor, constant: sidePadding),
            nameField.trailingAnchor.constraint(equalTo: nameClearButton.leadingAnchor, constant: -8),
            nameField.centerYAnchor.constraint(equalTo: nameCapsule.centerYAnchor),
            nameField.heightAnchor.constraint(lessThanOrEqualTo: nameCapsule.heightAnchor, constant: -20),

            nameClearButton.trailingAnchor.constraint(equalTo: nameCapsule.trailingAnchor, constant: -sidePadding),
            nameClearButton.centerYAnchor.constraint(equalTo: nameCapsule.centerYAnchor),
            nameClearButton.widthAnchor.constraint(equalToConstant: 20),
            nameClearButton.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        nameField.textField.addTarget(self, action: #selector(editingBegan),  for: .editingDidBegin)
        nameField.textField.addTarget(self, action: #selector(editingEnded),  for: .editingDidEnd)
        nameField.textField.addTarget(self, action: #selector(textChanged),   for: .editingChanged)

        nameClearButton.addTarget(self, action: #selector(clearNameTapped), for: .touchUpInside)

        // EMAIL
        vstack.addArrangedSubview(emailCapsule)

        // 1) The row’s main content (icon + label)
        let emailRow = UIStackView(arrangedSubviews: [emailIcon, emailLabel])
        emailRow.axis = .horizontal
        emailRow.alignment = .center
        emailRow.spacing = 8
        emailRow.translatesAutoresizingMaskIntoConstraints = false
        emailRow.isUserInteractionEnabled = false
        emailCapsule.addSubview(emailRow)

        // 2) The trailing verified badge (not inside the stack)
        emailCapsule.addSubview(verifiedIcon)

        NSLayoutConstraint.activate([
            // Main row pinned to leading, and to the left of the badge
            emailRow.leadingAnchor.constraint(equalTo: emailCapsule.leadingAnchor, constant: sidePadding),
            emailRow.centerYAnchor.constraint(equalTo: emailCapsule.centerYAnchor),

            // Leave a little air between label and badge
            emailRow.trailingAnchor.constraint(equalTo: verifiedIcon.leadingAnchor, constant: -12),

            // Badge aligns just like a chevron would:
            verifiedIcon.trailingAnchor.constraint(equalTo: emailCapsule.trailingAnchor, constant: -sidePadding),
            verifiedIcon.centerYAnchor.constraint(equalTo: emailCapsule.centerYAnchor)
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

        let resetRow = UIStackView(arrangedSubviews: [resetIcon, resetLabel])
        resetRow.axis = .horizontal
        resetRow.alignment = .center
        resetRow.spacing = 12
        resetRow.translatesAutoresizingMaskIntoConstraints = false
        resetRow.isUserInteractionEnabled = false
        resetControl.addSubview(resetRow)

        // Chev outside the stack so it shares the same trailing grid as the checkmark
        resetControl.addSubview(chevron)
        NSLayoutConstraint.activate([
            resetRow.leadingAnchor.constraint(equalTo: resetControl.leadingAnchor, constant: sidePadding),
            resetRow.centerYAnchor.constraint(equalTo: resetControl.centerYAnchor),
            resetRow.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            chevron.trailingAnchor.constraint(equalTo: resetControl.trailingAnchor, constant: -sidePadding),
            chevron.centerYAnchor.constraint(equalTo: resetControl.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 20),
            chevron.heightAnchor.constraint(equalToConstant: 20),
        ])

        resetControl.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        resetControl.addTarget(self, action: #selector(highlightDown), for: [.touchDown, .touchDragInside])
        resetControl.addTarget(self, action: #selector(highlightUp),   for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    // MARK: - Actions
    @objc private func resetTapped() { onChangePassword?() }
    @objc private func highlightDown() { animatePill(resetCapsule, pressed: true) }
    @objc private func highlightUp()   { animatePill(resetCapsule, pressed: false) }
    
    @objc private func clearNameTapped() {
        nameField.textField.text = ""
        updateClearVisibility()
        onChange?()
    }

    private func updateClearVisibility() {
        nameClearButton.isHidden = !(nameField.textField.isEditing && !(nameField.textField.text ?? "").isEmpty)
    }
    @objc private func editingBegan() { updateClearVisibility() }
    @objc private func editingEnded() { updateClearVisibility() }
    @objc private func textChanged()  { updateClearVisibility(); onChange?() }


    private func animatePill(_ v: UIView, pressed: Bool) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            v.alpha = pressed ? 0.85 : 1.0
            v.transform = pressed ? CGAffineTransform(scaleX: 0.99, y: 0.99) : .identity
        }
    }
}

