//
//  LoginViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

class LoginViewController: BaseAuthViewController {

    // MARK: - Specific UI Components
    private let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private let passwordField = AuthTextField(icon: UIImage(systemName: "lock.fill"), isSecure: true)
    private let forgotPasswordButton = LinkButton(title: "Forgot password?")
    private let loginButton = PrimaryButton(title: "Log In")
    private let switchToSignupButton = LinkButton(title: "Don't have an account? Sign up")

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        
        configureUI()
        setupLayout()
        setupTargets()
    }

    // MARK: - Setup
    private func configureUI() {
        // Configure titles inherited from base class
        titleLabel.text = "Welcome Back"
        
        // Configure specific UI
        emailField.textField.placeholder = "Email"
        passwordField.textField.placeholder = "Password"
        forgotPasswordButton.setTitleColor(.secondaryLabel, for: .normal)
        switchToSignupButton.setTitleColor(.secondaryLabel, for: .normal)
        
        // Assign components to base class properties for shared logic
        self.primaryButton = loginButton
        self.textFields = [emailField, passwordField]
    }
    
    private func setupLayout() {
        // Add specific components to the form stack view
        formStackView.addArrangedSubview(emailField)
        formStackView.addArrangedSubview(passwordField)
        
        // Use a container for the right-aligned forgot password button
        let forgotPasswordContainer = UIView()
        forgotPasswordContainer.addSubview(forgotPasswordButton)
        formStackView.addArrangedSubview(forgotPasswordContainer)
        
        formStackView.addArrangedSubview(loginButton)
        formStackView.setCustomSpacing(12, after: passwordField)
        formStackView.setCustomSpacing(20, after: forgotPasswordContainer)
        
        // Add the switch button to the main view
        view.addSubview(switchToSignupButton)
        
        [forgotPasswordButton, switchToSignupButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            forgotPasswordButton.topAnchor.constraint(equalTo: forgotPasswordContainer.topAnchor),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: forgotPasswordContainer.trailingAnchor),
            forgotPasswordButton.bottomAnchor.constraint(equalTo: forgotPasswordContainer.bottomAnchor),

            switchToSignupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchToSignupButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupTargets() {
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
        switchToSignupButton.addTarget(self, action: #selector(goToSignup), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func handleLogin() {
        guard let email = emailField.textField.text, !email.isEmpty,
              let password = passwordField.textField.text, !password.isEmpty else {
            presentAlert(title: "Missing Fields", message: "Please enter both email and password.")
            return
        }
        
        setLoading(true)
        AuthService.signIn(email: email, password: password) { [weak self] success in
            guard let self = self else { return }
            self.setLoading(false)
            if success {
                SceneDelegate.switchToMainApp()
            } else {
                self.presentAlert(title: "Login Failed", message: "Please check your email and password.")
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
}

