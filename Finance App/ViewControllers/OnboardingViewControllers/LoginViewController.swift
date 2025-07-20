//
//  LoginViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

final class LoginViewController: BaseAuthViewController {

    // MARK: - Unique UI Properties
    private let loginButton = PrimaryButton(title: "Log In")
    private let forgotPasswordButton = LinkButton(title: "Forgot password?")
    private let switchToSignupButton = LinkButton(title: "Don't have an account? Sign up")

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Welcome Back"
        subtitleLabel.text = "Sign in to continue."

        setupUniqueSubviews()
        setupUniqueConstraints()
        setupUniqueTargets()
    }

    // MARK: - Unique Setup
    private func setupUniqueSubviews() {
        switchToSignupButton.setTitleColor(.secondaryLabel, for: .normal)
        forgotPasswordButton.setTitleColor(.secondaryLabel, for: .normal)
        
        guard let cardContentView = (glassCard.subviews.first as? UIVisualEffectView)?.contentView else { return }
        
        cardContentView.addSubview(loginButton)
        cardContentView.addSubview(forgotPasswordButton)
        view.addSubview(switchToSignupButton)
    }

    private func setupUniqueConstraints() {
        [loginButton, forgotPasswordButton, switchToSignupButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            emailField.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 24),
            
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 12),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),
            
            loginButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 12),
            loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            
            separatorLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            
            appleSignInButton.topAnchor.constraint(equalTo: separatorLabel.bottomAnchor, constant: 16),
            appleSignInButton.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -24),
            
            switchToSignupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchToSignupButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func setupUniqueTargets() {
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
        switchToSignupButton.addTarget(self, action: #selector(goToSignup), for: .touchUpInside)
    }

    // MARK: - Unique Actions
    @objc private func handleLogin() {
        guard let email = emailField.textField.text, !email.isEmpty,
              let password = passwordField.textField.text, !password.isEmpty else {
            showAlert(title: "Missing Fields", message: "Please enter both email and password.")
            return
        }
        
        setLoading(true)
        AuthService.signIn(email: email, password: password) { [weak self] success in
            guard let self = self else { return }
            self.setLoading(false)
            if success {
                SceneDelegate.switchToMainApp()
            } else {
                self.showAlert(title: "Login Failed", message: "Please check your email and password.")
            }
        }
    }

    @objc private func handleForgotPassword() {
        let vc = ResetPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func goToSignup() {
        let vc = SignupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Overrides
    override func setLoading(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        appleSignInButton.isEnabled = !isLoading
        googleSignInButton.isEnabled = !isLoading
        
        emailField.isUserInteractionEnabled = !isLoading
        passwordField.isUserInteractionEnabled = !isLoading
        
        let buttonTitle = isLoading ? "Logging In..." : "Log In"
        loginButton.setTitle(buttonTitle, for: .normal)
    }
}

