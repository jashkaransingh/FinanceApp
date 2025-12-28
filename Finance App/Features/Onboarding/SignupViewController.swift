//
//  SignupViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

final class SignupViewController: BaseAuthViewController {
    
    private let nameField = AuthTextField(icon: UIImage(systemName: "person.fill"))
    private let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    private let passwordField = AuthTextField(icon: UIImage(systemName: "lock.fill"), isSecure: true)
    
    private let signupButton = PrimaryButton(title: "Create Account")
    private let switchToLoginButton = LinkButton(title: "Already have an account? Log In")
    
    private var validationWorkItem: DispatchWorkItem?
    
    private let passwordRequirementsLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = UIFont.preferredFont(forTextStyle: .subheadline)
        lbl.adjustsFontForContentSizeCategory = true
        lbl.textColor = .secondaryLabel
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupLayout()
        setupTargets()
        refreshUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        validationWorkItem?.cancel()
    }
    
    private func configureUI() {
        titleLabel.text = "Create Account"
        
        primaryButton = signupButton
        textFields = [nameField, emailField, passwordField]
        loadingControls = [switchToLoginButton]
        
        nameField.textField.placeholder = "Full Name"
        nameField.textField.textContentType = .name
        nameField.textField.autocapitalizationType = .words
        
        emailField.textField.placeholder = "Email"
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.textContentType = .emailAddress
        
        passwordField.textField.placeholder = "Password"
        passwordField.textField.textContentType = .newPassword
        
        nameField.textField.enablesReturnKeyAutomatically = true
        emailField.textField.enablesReturnKeyAutomatically = true
        passwordField.textField.enablesReturnKeyAutomatically = true
        
        textFields.forEach {
            $0.textField.addTarget(self, action: #selector(textFieldsDidChange(_:)), for: .editingChanged)
        }
        
        signupButton.isEnabled = false
    }
    
    private func setupLayout() {
        formStackView.addArrangedSubview(nameField)
        formStackView.addArrangedSubview(emailField)
        formStackView.addArrangedSubview(passwordField)
        
        formStackView.addArrangedSubview(passwordRequirementsLabel)
        formStackView.setCustomSpacing(6, after: passwordField)
        
        formStackView.addArrangedSubview(signupButton)
        formStackView.setCustomSpacing(12, after: signupButton)
        
        formStackView.addArrangedSubview(switchToLoginButton)
    }
    
    private func setupTargets() {
        signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
        switchToLoginButton.addTarget(self, action: #selector(goToLogin), for: .touchUpInside)
    }
    
    private func refreshUI() {
        updateNameFieldUI()
        updateEmailFieldUI()
        updatePasswordRequirementsUI()
        updateSignupButtonState()
    }
    
    private func updateNameFieldUI() {
        let valid = nameField.textField.text?.isValidSimpleName ?? false
        nameField.iconTintColor = valid ? .systemGreen : .secondaryLabel
    }
    
    private func updateEmailFieldUI() {
        let valid = emailField.textField.text?.isValidEmail() ?? false
        emailField.iconTintColor = valid ? .systemGreen : .secondaryLabel
    }
    
    private func updateSignupButtonState() {
        let nameOK  = nameField.textField.text?.isValidSimpleName ?? false
        let emailOK = emailField.textField.text?.isValidEmail() ?? false
        let pass    = passwordField.textField.text ?? ""
        let passOK  = PasswordRules.evaluate(pass).valid
        signupButton.isEnabled = nameOK && emailOK && passOK && !isLoading
    }
    
    private func updatePasswordRequirementsUI() {
        let pw = passwordField.textField.text ?? ""
        let result = PasswordRules.evaluate(pw)
        
        let textStyle: UIFont.TextStyle = .footnote
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let baseFont = UIFont.preferredFont(forTextStyle: textStyle)
        let font = metrics.scaledFont(for: baseFont)
        
        let full = NSMutableAttributedString()
        for rule in result.checks {
            let marker = rule.passed ? "✓" : "•"
            let color: UIColor = rule.passed ? .systemGreen : .secondaryLabel
            full.append(NSAttributedString(
                string: "\(marker) \(rule.label)\n",
                attributes: [.foregroundColor: color, .font: font]
            ))
        }
        passwordRequirementsLabel.attributedText = full
    }
    
    @objc private func textFieldsDidChange(_ tf: UITextField) {
        validationWorkItem?.cancel()
        
        let work = DispatchWorkItem { [weak self] in
            self?.refreshUI()
        }
        validationWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
    
    @objc private func handleSignup() {
        guard !isLoading else { return }
        refreshUI()
        
        guard guardOnlineOrAlert() else {
            refreshUI()
            return
        }
        
        let name = nameField.textField.trimmedText
        let email = emailField.textField.trimmedText
        let password = passwordField.textField.trimmedText
        
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            presentAlert(title: "Missing Information", message: "Please fill out all fields.")
            refreshUI()
            return
        }
        
        setLoading(true)
        
        AuthService.register(email: email, password: password, name: name) { [weak self] result in
            guard let self else { return }
            onMain {
                self.setLoading(false)
                self.refreshUI()
                
                switch result {
                case .success:
                    if AppFlags.requireEmailVerification {
                        let vc = VerifyEmailViewController(email: email)
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        SceneDelegate.switchToMainApp()
                    }
                    
                case .failure(let error):
                    let message: String
                    switch error {
                    case .weakPassword:
                        message = "Your password is too weak—please add uppercase letters, numbers, and special characters."
                    case .emailAlreadyInUse:
                        message = "An account with this email already exists."
                    case .networkError:
                        message = "Network error—please check your connection and try again."
                    case .unknown(let desc):
                        message = desc
                    default:
                        message = "Registration failed. Please try again."
                    }
                    self.presentAlert(title: "Registration Failed", message: message)
                }
            }
        }
    }
    
    @objc private func goToLogin() {
        popSmoothly()
    }
}

