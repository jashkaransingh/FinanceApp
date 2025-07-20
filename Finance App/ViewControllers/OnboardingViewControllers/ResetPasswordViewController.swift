//
//  ResetPasswordViewController.swift
//  Finance App
//
//  Created by Jas  on 5/27/25.
//

import UIKit
import FirebaseAuth

class ResetPasswordViewController: UIViewController {

    // MARK: - UI Properties
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "marble_background")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Reset Password"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your email to receive a reset link."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private let glassCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        view.layer.cornerRadius = 24
        view.clipsToBounds = true

        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)

        return view
    }()

    // Use the new, modern text field
    private lazy var emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private let sendLinkButton = PrimaryButton(title: "Send Reset Link")
    private let backToLoginButton = LinkButton(title: "Back to Login")

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .label
        setupSubviews()
        setupConstraints()
        setupTargets()
    }

    // MARK: - Setup
    private func setupSubviews() {
        emailField.textField.placeholder = "Email"
        backToLoginButton.setTitleColor(.secondaryLabel, for: .normal)

        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(glassCard)

        guard let cardContentView = (glassCard.subviews.first as? UIVisualEffectView)?.contentView else { return }
        
        cardContentView.addSubview(emailField)
        cardContentView.addSubview(sendLinkButton)
        cardContentView.addSubview(backToLoginButton)
    }

    private func setupConstraints() {
        let allViews = [backgroundImageView, titleLabel, subtitleLabel, glassCard, emailField, sendLinkButton, backToLoginButton]
        allViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),

            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: glassCard.topAnchor, constant: -24),

            glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            glassCard.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            // --- Constraints for items inside the card ---
            emailField.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 24),
            emailField.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
            emailField.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),

            sendLinkButton.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 24),
            sendLinkButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            sendLinkButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),

            backToLoginButton.topAnchor.constraint(equalTo: sendLinkButton.bottomAnchor, constant: 16),
            backToLoginButton.centerXAnchor.constraint(equalTo: glassCard.centerXAnchor),
            backToLoginButton.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -24)
        ])
    }

    private func setupTargets() {
        sendLinkButton.addTarget(self, action: #selector(handleSendLink), for: .touchUpInside)
        backToLoginButton.addTarget(self, action: #selector(handleBackToLogin), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func handleSendLink() {
        guard let email = emailField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            presentAlert(title: "Missing Email", message: "Please enter your email address.")
            return
        }

        // The Firebase logic remains the same
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Reset error: \(error.localizedDescription)")
                self.presentAlert(title: "Failed", message: "Unable to send reset link. Try again later.")
            } else {
                self.presentAlert(title: "Success", message: "Password reset link sent. Check your email.") {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    @objc private func handleBackToLogin() {
        navigationController?.popViewController(animated: true)
    }

    private func presentAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

