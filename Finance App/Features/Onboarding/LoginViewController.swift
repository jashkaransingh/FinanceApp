//
//  LoginViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

final class LoginViewController: BaseAuthViewController {
    
    private let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private let passwordField = AuthTextField(icon: UIImage(systemName: "lock.fill"), isSecure: true)
    
    private let forgotPasswordButton = LinkButton(title: "Forgot password?")
    private let loginButton = PrimaryButton(title: "Log In")
    private let switchToSignupButton = LinkButton(title: "Don't have an account? Sign up")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupLayout()
        setupTargets()
        updateLoginButtonState()
        
        textFields.forEach {
            $0.textField.addTarget(self,
                                   action: #selector(loginTextFieldsDidChange(_:)),
                                   for: .editingChanged)
        }
    }
    
    private func configureUI() {
        titleLabel.text = "Welcome Back"
        
        emailField.textField.placeholder = "Email"
        passwordField.textField.placeholder = "Password"
        
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.textContentType = .username
        
        passwordField.textField.textContentType = .password
        
        emailField.textField.enablesReturnKeyAutomatically = true
        passwordField.textField.enablesReturnKeyAutomatically = true
        
        primaryButton = loginButton
        textFields = [emailField, passwordField]
        loadingControls = [forgotPasswordButton, switchToSignupButton]
    }
    
    private func setupLayout() {
        formStackView.addArrangedSubview(emailField)
        formStackView.addArrangedSubview(passwordField)
        
        let forgotPasswordContainer = UIView()
        forgotPasswordContainer.addSubview(forgotPasswordButton)
        formStackView.addArrangedSubview(forgotPasswordContainer)
        
        formStackView.addArrangedSubview(loginButton)
        formStackView.setCustomSpacing(12, after: passwordField)
        formStackView.setCustomSpacing(20, after: forgotPasswordContainer)
        
        view.addSubview(switchToSignupButton)
        
        [forgotPasswordButton, switchToSignupButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            forgotPasswordButton.topAnchor.constraint(equalTo: forgotPasswordContainer.topAnchor),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: forgotPasswordContainer.trailingAnchor),
            forgotPasswordButton.bottomAnchor.constraint(equalTo: forgotPasswordContainer.bottomAnchor),
            forgotPasswordButton.leadingAnchor.constraint(greaterThanOrEqualTo: forgotPasswordContainer.leadingAnchor),
            
            switchToSignupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchToSignupButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupTargets() {
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
        switchToSignupButton.addTarget(self, action: #selector(goToSignup), for: .touchUpInside)
    }
    
    private func updateLoginButtonState() {
        let emailOK = emailField.textField.text?.isValidEmail() ?? false
        let passOK = (passwordField.textField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
        loginButton.isEnabled = emailOK && passOK && !isLoading
    }
    
    @objc private func loginTextFieldsDidChange(_ tf: UITextField) {
        updateLoginButtonState()
    }
    
    @objc private func handleLogin() {
        guard !isLoading else { return }
        
        guard guardOnlineOrAlert() else { return }
        
        let email = emailField.textField.trimmedText
        let password = passwordField.textField.trimmedText
        
        guard !email.isEmpty, !password.isEmpty else {
            presentAlert(title: "Missing Fields",
                         message: "Please enter both email and password.")
            return
        }
        
        if !email.isValidEmail() {
            presentAlert(title: "Invalid Email",
                         message: "Please check the format of your email address.")
            return
        }
        
        guard password.count >= 3 else {
            presentAlert(title: "Password Too Short",
                         message: "Please enter at least 3 characters.")
            return
        }
        
        setLoading(true)
        AuthService.signIn(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            onMain {
                self.setLoading(false)
                self.updateLoginButtonState()
                
                switch result {
                case .success:
                    SharedDataManager.shared.reloadUserProfile { result in
                        onMain {
                            switch result {
                            case .success:
                                SceneDelegate.switchToMainApp()
                            case .failure(let error):
                                print("Failed to load profile:", error)
                                SceneDelegate.switchToMainApp()
                            }
                        }
                    }
                    
                case .failure(let error):
                    let msg: String
                    switch error {
                    case .userNotFound:  msg = "No account found for that email."
                    case .wrongPassword: msg = "That password looks incorrect."
                    case .networkError:  msg = "Please check your connection and try again."
                    default:             msg = "Login failed. Please try again."
                    }
                    self.presentAlert(title: "Login Failed", message: msg)
                }
            }
        }
    }
    
    @objc private func goToSignup() {
        pushSmoothly(SignupViewController())
    }
    
    @objc private func handleForgotPassword() {
        let email = emailField.textField.trimmedText
        let prefill = email.isEmpty ? nil : email
        pushSmoothly(ResetPasswordViewController(mode: .authFlow, prefillEmail: prefill))
    }
}
