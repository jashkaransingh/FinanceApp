//
//  ResetPasswordViewController.swift
//  Finance App
//
//  Created by Jas  on 5/27/25.
//

import UIKit
import FirebaseAuth

final class ResetPasswordViewController: BaseAuthViewController {

    // MARK: UI
    private let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private let backToLoginButton = LinkButton(title: "Back to Login")
    var prefillEmail: String?

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Reset Password"
        subtitleLabel.text = "Enter your email to receive a reset link."

        // Decide initial email once (prefer explicit prefill)
        let initialEmail = (prefillEmail?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? Auth.auth().currentUser?.email
        emailField.textField.text = initialEmail

        setupSubviews()
        setupTargets()

        // Ensure the primary button matches the prefilled text
        textDidChange()

        // Hide social section from the base class
        googleSignInButton.superview?.isHidden = true
        (googleSignInButton.superview?.superview?.subviews.first { ($0 as? UILabel)?.text == "or" })?.isHidden = true
    }

    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationItem.largeTitleDisplayMode = .never   // <- important
        }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Kill the keyboard so pop animation isn’t fighting it
        view.endEditing(true)
    }


    // MARK: Setup
    private func setupSubviews() {
        emailField.textField.placeholder = "Email"
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        emailField.textField.returnKeyType = .go

        backToLoginButton.setTitleColor(.secondaryLabel, for: .normal)

        // Build the base form
        formStackView.addArrangedSubview(emailField)

        // Replace the base primary button
        primaryButton = PrimaryButton(title: "Send Reset Link")
        formStackView.addArrangedSubview(primaryButton)

        formStackView.addArrangedSubview(backToLoginButton)
        formStackView.setCustomSpacing(24, after: primaryButton)

        textFields = [emailField]
    }

    private func setupTargets() {
        primaryButton.addTarget(self, action: #selector(handleSendLink), for: .touchUpInside)
        backToLoginButton.addTarget(self, action: #selector(handleBackToLogin), for: .touchUpInside)

        // Pressing “Go” on the keyboard submits
        emailField.textField.addTarget(self, action: #selector(handleSendLink), for: .editingDidEndOnExit)

        // Enable/disable button as user types
        emailField.textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        primaryButton.isEnabled = !(emailField.textField.text ?? "").isEmpty
    }

    // MARK: Actions
    @objc private func textDidChange() {
        primaryButton.isEnabled = !(emailField.textField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    @objc private func handleSendLink() {
        view.endEditing(true)

        let email = (emailField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(email) else {
            presentAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }

        setLoading(true)
        AuthService.resetPassword(email: email) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                // Only proceed if we're still visible AND still the top controller
                guard self.viewIfLoaded?.window != nil,
                      self.navigationController?.topViewController === self else {
                    return
                }

                self.setLoading(false)

                // Show a generic “success” to avoid revealing whether the email exists
                switch result {
                case .success:
                    self.presentAlert(title: "Email Sent",
                                      message: "If an account exists for \(email), we’ve sent a reset link.")
                case .failure(let error):
                    let code = AuthErrorCode(_bridgedNSError: error as NSError)
                    switch code?.code {
                    case .userNotFound, .invalidEmail:
                        self.presentAlert(title: "Email Sent",
                                          message: "If an account exists for \(email), we’ve sent a reset link.")
                    case .tooManyRequests:
                        self.presentAlert(title: "Too Many Requests",
                                          message: "Please wait a bit and try again.")
                    case .networkError:
                        self.presentAlert(title: "Network Error",
                                          message: "Check your connection and try again.")
                    default:
                        self.presentAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc private func handleBackToLogin() {
        view.endEditing(true) // also handle the explicit back tap
        navigationController?.popViewController(animated: true)
    }


    // MARK: Helpers
    private func isValidEmail(_ email: String) -> Bool {
        // Simple, pragmatic check
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}


