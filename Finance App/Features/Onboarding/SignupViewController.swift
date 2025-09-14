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
    private let switchToLoginButton = LinkButton(title: "Already have an account? Log In")
    private var validationWorkItem: DispatchWorkItem?
    private var isSubmitting = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        updateSignupButtonState()
        updateNameFieldUI()
        updatePasswordRequirementsUI()
        updateEmailFieldUI()
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
        self.primaryButton = signupButton
        self.textFields = [nameField, emailField, passwordField]
        
        textFields.forEach {
            $0.textField.addTarget(self,
                                   action: #selector(textFieldsDidChange(_:)),
                                   for: .editingChanged)
        }
        // disable button until valid
        
        signupButton.isEnabled = false
        
        // Configure specific UI
        nameField.textField.placeholder = "Full Name"
        emailField.textField.placeholder = "Email"
        passwordField.textField.placeholder = "Password"
        nameField.textField.textContentType = .name
        nameField.textField.autocapitalizationType = .words
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.textContentType = .emailAddress

        // Password: use .newPassword on signup to trigger strong suggestions
        passwordField.textField.textContentType = .newPassword

        // Optional: only enable return when there’s text
        nameField.textField.enablesReturnKeyAutomatically = true
        emailField.textField.enablesReturnKeyAutomatically = true
        passwordField.textField.enablesReturnKeyAutomatically = true
    }
    
    private let passwordRequirementsLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        // Use a Dynamic Type style
        lbl.font = UIFont.preferredFont(forTextStyle: .subheadline)
        lbl.adjustsFontForContentSizeCategory = true
        lbl.textColor = .secondaryLabel
        return lbl
    }()
    
    private func updateNameFieldUI() {
        let valid = nameField.textField.text?.isValidSimpleName ?? false
        nameField.iconTintColor = valid ? .systemGreen : .secondaryLabel
    }
    
    private func updateSignupButtonState() {
        let nameOK  = nameField.textField.text?.isValidSimpleName ?? false
        let emailOK = emailField.textField.text?.isValidEmail() ?? false
        let pass    = passwordField.textField.text ?? ""
        let passOK  = PasswordRules.evaluate(pass).valid
        signupButton.isEnabled = nameOK && emailOK && passOK
    }
    private func updatePasswordRequirementsUI() {
        let pw = passwordField.textField.text ?? ""
        let result = PasswordRules.evaluate(pw)

        let full = NSMutableAttributedString()
        let textStyle: UIFont.TextStyle = .footnote
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let baseFont = UIFont.preferredFont(forTextStyle: textStyle)
        let font = metrics.scaledFont(for: baseFont)

        for rule in result.checks {
            let check = rule.passed ? "✓" : "•"
            let color: UIColor = rule.passed ? .systemGreen : .secondaryLabel
            full.append(NSAttributedString(string: "\(check) \(rule.label)\n",
                                           attributes: [.foregroundColor: color, .font: font]))
        }

        passwordRequirementsLabel.attributedText = full
    }
    
    private func updateEmailFieldUI() {
        let valid = emailField.textField.text?.isValidEmail() ?? false
        emailField.iconTintColor = valid ? .systemGreen : .secondaryLabel
    }
    
    
    private func setupLayout() {
        // Add specific components to the form stack view
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
        signupButton.addTarget(self,    action: #selector(handleSignup),      for: .touchUpInside)
        switchToLoginButton.addTarget(self, action: #selector(goToLogin),    for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleSignup() {
        
        guard !isSubmitting else { return }
        isSubmitting = true
        signupButton.isEnabled = false
        
        if !NetworkMonitor.shared.isConnected {
            presentAlert(title: "No Internet Connection",
                         message: "Please check your network and try again.")
            isSubmitting = false
            updateSignupButtonState()   // re-enables only if inputs are valid
            return
        }

        let name     = nameField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email    = emailField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            presentAlert(title: "Missing Information", message: "Please fill out all fields.")
            isSubmitting = false
            updateSignupButtonState()
            return
        }

        setLoading(true)
        AuthService.register(email: email, password: password, name: name) { [weak self] result in
            guard let self = self else { return }
            onMain {
                self.setLoading(false)
                self.isSubmitting = false
                switch result {
                case .success:
                    let vc = VerifyEmailViewController(email: email)
                    self.navigationController?.pushViewController(vc, animated: true)
                case .failure(let error):
                    let message: String
                    switch error {
                    case .weakPassword:         message = "Your password is too weak—please add uppercase letters, numbers, and special characters."
                    case .emailAlreadyInUse:    message = "An account with this email already exists."
                    case .networkError:         message = "Network error—please check your connection and try again."
                    case .unknown(let desc):    message = desc
                    default:                    message = "Registration failed. Please try again."
                    }
                    self.presentAlert(title: "Registration Failed", message: message)
                    self.updateSignupButtonState()
                }
            }
        }
    }
    
    @objc private func goToLogin() {
        navigationController?.popViewController(animated: true)
    }
    @objc private func textFieldsDidChange(_ tf: UITextField) {
        // Cancel any pending validation
        validationWorkItem?.cancel()
        
        // Schedule a new one in 0.3s
        let work = DispatchWorkItem { [weak self] in
            self?.updateSignupButtonState()
            self?.updatePasswordRequirementsUI()
            self?.updateEmailFieldUI()
            self?.updateNameFieldUI()
        }
        validationWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
}

extension String {
    var isValidSimpleName: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }
}
