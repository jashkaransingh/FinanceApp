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
    private var isSubmitting = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        
        configureUI()
        setupLayout()
        setupTargets()
        loginButton.isEnabled = false
        textFields.forEach {
            $0.textField.addTarget(self,
                                   action: #selector(loginTextFieldsDidChange(_:)),
                                   for: .editingChanged)
        }
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
        
        // Email: proper keyboard + autofill
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.textContentType = .username   // improves Keychain autofill

        // Password: correct content type for login
        passwordField.textField.textContentType = .password

        // Optional but nice: only enable return when there’s text
        emailField.textField.enablesReturnKeyAutomatically = true
        passwordField.textField.enablesReturnKeyAutomatically = true

        
        loginButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        loginButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        forgotPasswordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        forgotPasswordButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        switchToSignupButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        switchToSignupButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
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
    
    @objc private func loginTextFieldsDidChange(_ tf: UITextField) {
        let emailOK = emailField.textField.text?.isValidEmail() ?? false
        let passOK  = (passwordField.textField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
        loginButton.isEnabled = emailOK && passOK
    }
    
    @objc private func handleLogin() {
        guard !isSubmitting else { return }
        isSubmitting = true
        loginButton.isEnabled = false

        if !NetworkMonitor.shared.isConnected {
            presentAlert(title: "No Internet Connection",
                         message: "Please check your network and try again.")
            isSubmitting = false
            loginButton.isEnabled = true
            return
        }
        
        // 1) Trim whitespace/newlines
        let email    = emailField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // 2) Validate non-empty
        guard !email.isEmpty, !password.isEmpty else {
            presentAlert(title: "Missing Fields",
                         message: "Please enter both email and password.")
            isSubmitting = false
            loginButton.isEnabled = true
            return
        }
        
        // 3) Validate format
        if !email.isValidEmail() {
            presentAlert(title: "Invalid Email",
                         message: "Please check the format of your email address.")
            isSubmitting = false
            loginButton.isEnabled = true
            return
        }
        guard password.count >= 3 else {
            presentAlert(title: "Password Too Short",
                         message: "Please enter at least 3 characters.")
            isSubmitting = false
            loginButton.isEnabled = true
            return
        }

        
        // 4) Proceed
        setLoading(true)
        AuthService.signIn(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            onMain {
                self.setLoading(false)
                self.isSubmitting = false
                switch result {
                case .success:
                    SharedDataManager.shared.reloadUserProfile { result in
                        onMain {
                            switch result {
                            case .success(_):
                                SceneDelegate.switchToMainApp()
                            case .failure(let error):
                                print("❌ Failed to load profile:", error)
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
                    default:             msg = "Login failed—please try again."
                    }
                    self.presentAlert(title: "Login Failed", message: msg)
                    self.loginButton.isEnabled = true
                }
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

