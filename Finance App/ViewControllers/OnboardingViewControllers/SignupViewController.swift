//
//  SignupViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

final class SignupViewController: BaseAuthViewController {
    
    // MARK: - Unique UI Properties
    private let nameField = AuthTextField(icon: UIImage(systemName: "person.fill"))
    private let signupButton = PrimaryButton(title: "Create Account")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        // This calls all the setup methods in the base class first
        super.viewDidLoad()
        
        // Now, configure the unique parts for this screen
        titleLabel.text = "Create Account"
        subtitleLabel.text = "Start tracking your finances."
        
        setupUniqueSubviews()
        setupUniqueConstraints()
        setupUniqueTargets()
    }
    
    // MARK: - Unique Setup
    private func setupUniqueSubviews() {
        nameField.textField.placeholder = "Full Name"
        
        guard let cardContentView = (glassCard.subviews.first as? UIVisualEffectView)?.contentView else { return }
        
        cardContentView.addSubview(nameField)
        cardContentView.addSubview(signupButton)
    }
    
    private func setupUniqueConstraints() {
        [nameField, signupButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            // Constraint chain inside the card
            nameField.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
            
            emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            
            signupButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 24),
            signupButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            signupButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            
            separatorLabel.topAnchor.constraint(equalTo: signupButton.bottomAnchor, constant: 20),
            
            appleSignInButton.topAnchor.constraint(equalTo: separatorLabel.bottomAnchor, constant: 16),
            appleSignInButton.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -24),
        ])
    }
    
    private func setupUniqueTargets() {
        signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
    }
    
    // MARK: - Unique Actions
    @objc private func handleSignup() {
        guard let name = nameField.textField.text, !name.isEmpty,
              let email = emailField.textField.text, !email.isEmpty,
              let password = passwordField.textField.text, !password.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill out all fields.")
            return
        }
        
        setLoading(true)
        AuthService.register(email: email, password: password, name: name) { [weak self] success in
            guard let self = self else { return }
            self.setLoading(false)
            if success {
                SceneDelegate.switchToMainApp()
            } else {
                self.showAlert(title: "Registration Failed", message: "An error occurred during registration.")
            }
        }
    }
    
    // MARK: - Overrides
    override func setLoading(_ isLoading: Bool) {
        signupButton.isEnabled = !isLoading
        appleSignInButton.isEnabled = !isLoading
        googleSignInButton.isEnabled = !isLoading
        
        nameField.isUserInteractionEnabled = !isLoading
        emailField.isUserInteractionEnabled = !isLoading
        passwordField.isUserInteractionEnabled = !isLoading
        
        let buttonTitle = isLoading ? "Creating Account..." : "Create Account"
        signupButton.setTitle(buttonTitle, for: .normal)
    }
}

