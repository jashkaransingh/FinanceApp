//
//  SignupViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

class SignupViewController: BaseAuthViewController {
    
    // MARK: - Specific UI Components
    private let nameField = AuthTextField(icon: UIImage(systemName: "person.fill"))
    private let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private let passwordField = AuthTextField(icon: UIImage(systemName: "lock.fill"), isSecure: true)
    private let signupButton = PrimaryButton(title: "Create Account")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        setupLayout()
        setupTargets()
    }
    
    // MARK: - Setup
    private func configureNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = .label
    }
    
    private func configureUI() {
        // Configure titles inherited from base class
        titleLabel.text = "Create Account"
        
        // Configure specific UI
        nameField.textField.placeholder = "Full Name"
        emailField.textField.placeholder = "Email"
        passwordField.textField.placeholder = "Password"
        
        // Assign components to base class properties for shared logic
        self.primaryButton = signupButton
        self.textFields = [nameField, emailField, passwordField]
    }

    private func setupLayout() {
        // Add specific components to the form stack view
        formStackView.addArrangedSubview(nameField)
        formStackView.addArrangedSubview(emailField)
        formStackView.addArrangedSubview(passwordField)
        formStackView.addArrangedSubview(signupButton)
        formStackView.setCustomSpacing(24, after: passwordField)
    }
    
    private func setupTargets() {
        signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleSignup() {
        guard let name = nameField.textField.text, !name.isEmpty,
              let email = emailField.textField.text, !email.isEmpty,
              let password = passwordField.textField.text, !password.isEmpty else {
            presentAlert(title: "Missing Information", message: "Please fill out all fields.")
            return
        }
        
        setLoading(true)
        AuthService.register(email: email, password: password, name: name) { [weak self] success in
            guard let self = self else { return }
            self.setLoading(false)
            if success {
                SceneDelegate.switchToMainApp()
            } else {
                self.presentAlert(title: "Registration Failed", message: "An error occurred during registration.")
            }
        }
    }
}
