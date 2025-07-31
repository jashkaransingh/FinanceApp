//
//  ResetPasswordViewController.swift
//  Finance App
//
//  Created by Jas  on 5/27/25.
//

import UIKit
import FirebaseAuth

class ResetPasswordViewController: BaseAuthViewController {
    
    // MARK: - UI Properties
    private let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private let backToLoginButton = LinkButton(title: "Back to Login")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        // 1. Call the parent's viewDidLoad
        super.viewDidLoad()
        
        // 2. Configure the UI inherited from the base class
        self.titleLabel.text = "Reset Password"
        self.subtitleLabel.text = "Enter your email to receive a reset link."
        
        // 3. Configure the specific UI for this screen
        setupSubviews()
        setupTargets()
        
        // 4. Hide the social login buttons from the base class
        // Accessing the superview of one button gets us the StackView they are in.
        googleSignInButton.superview?.isHidden = true
        // And the "or" separator label
        (googleSignInButton.superview?.superview?.subviews.first { $0 is UILabel && ($0 as! UILabel).text == "or" })?.isHidden = true
    }
    
    // MARK: - Setup
    private func setupSubviews() {
        // Configure local UI elements
        emailField.textField.placeholder = "Email"
        backToLoginButton.setTitleColor(.secondaryLabel, for: .normal)
        
        // Add our unique views to the base class's form stack
        formStackView.addArrangedSubview(emailField)
        
        // NOTE: We are replacing the primary button in the base class.
        // The base class only has one primary button, which we will set to our "Send Reset Link"
        primaryButton = PrimaryButton(title: "Send Reset Link")
        formStackView.addArrangedSubview(primaryButton)
        
        formStackView.addArrangedSubview(backToLoginButton)
        formStackView.setCustomSpacing(24, after: primaryButton) // Adds extra space after the main button
        
        // Configure properties for the base class to use
        textFields = [emailField]
    }
    
    private func setupTargets() {
        primaryButton.addTarget(self, action: #selector(handleSendLink), for: .touchUpInside)
        backToLoginButton.addTarget(self, action: #selector(handleBackToLogin), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleSendLink() {
        guard let email = emailField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            presentAlert(title: "Missing Email", message: "Please enter your email address.")
            return
        }
        
        // Use the setLoading and AuthService methods from the base class and service
        setLoading(true)
        AuthService.resetPassword(email: email) { [weak self] ok in
          let alert = UIAlertController(title: ok ? "✔️ Email Sent" : "Error",
                                        message: ok ? "Check your inbox." : "Try again later.",
                                        preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if ok {
              self?.navigationController?.popViewController(animated: true)
            }
          })
          self?.present(alert, animated: true)
        }

    }
    
    @objc private func handleBackToLogin() {
        navigationController?.popViewController(animated: true)
    }
}

