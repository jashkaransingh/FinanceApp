//
//  ResetPasswordViewController.swift
//  Finance App
//
//  Created by Jas  on 5/27/25.
//

import UIKit
import FirebaseAuth

enum ResetPasswordMode {
    case authFlow
    case inApp
}


final class ResetPasswordViewController: BaseAuthViewController {
    
    // MARK: UI
    private let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private lazy var backToLoginButton = LinkButton(title: "Back to Login")
    private let sendLinkButton = PrimaryButton(title: "Send Reset Link")
    private let mode: ResetPasswordMode
    private let prefillEmail: String?
    
    
    init(mode: ResetPasswordMode = .authFlow, prefillEmail: String? = nil) {
        self.mode = mode
        self.prefillEmail = prefillEmail
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        setSocialSectionHidden(true)
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

        formStackView.addArrangedSubview(emailField)

        primaryButton = sendLinkButton
        formStackView.addArrangedSubview(sendLinkButton)
        formStackView.setCustomSpacing(24, after: sendLinkButton)

        if mode == .authFlow {
            formStackView.addArrangedSubview(backToLoginButton)
            loadingControls = [backToLoginButton]
        } else {
            loadingControls = []
        }

        textFields = [emailField]
    }
    
    private func setupTargets() {
        sendLinkButton.addTarget(self, action: #selector(handleSendLink), for: .touchUpInside)

        if mode == .authFlow {
            backToLoginButton.addTarget(self, action: #selector(handleBackToLogin), for: .touchUpInside)
        }

        emailField.textField.addTarget(self, action: #selector(handleSendLink), for: .editingDidEndOnExit)
        emailField.textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textDidChange()
    }
    
    // MARK: Actions
    @objc private func textDidChange() {
        sendLinkButton.isEnabled = !(emailField.textField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    @objc private func handleSendLink() {
        view.endEditing(true)
        
        let email = emailField.textField.trimmedText
        guard email.isValidEmail() else {
            presentAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }
        
        guard guardOnlineOrAlert() else { return }
        
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
        popSmoothly()
    }
}
