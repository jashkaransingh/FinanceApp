//
//  ResetPasswordViewController.swift
//  Finance App
//
//  Created by Jas  on 5/27/25.
//

import UIKit
import FirebaseAuth

class ResetPasswordViewController: UIViewController {

    private let emailField = CustomTextField(placeholder: "Enter your email")
    private let sendLinkButton = PrimaryButton(title: "Send Reset Link")
    private let backToLoginButton = LinkButton(title: "Back to Login")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Reset Password"
        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {
        [emailField, sendLinkButton, backToLoginButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        sendLinkButton.addTarget(self, action: #selector(handleSendLink), for: .touchUpInside)
        backToLoginButton.addTarget(self, action: #selector(handleBackToLogin), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            emailField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            sendLinkButton.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 24),
            sendLinkButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            sendLinkButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),

            backToLoginButton.topAnchor.constraint(equalTo: sendLinkButton.bottomAnchor, constant: 16),
            backToLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func handleSendLink() {
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            presentAlert(title: "Missing Email", message: "Please enter your email address.")
            return
        }

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

