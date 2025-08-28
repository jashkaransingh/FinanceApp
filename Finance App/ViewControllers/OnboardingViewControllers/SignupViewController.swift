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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        updateSignupButtonState()
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
        nameField.textField.textContentType = .namePrefix
        passwordField.textField.textContentType = .password
        emailField.textField.textContentType = .emailAddress
    }
    
    private let passwordRequirementsLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        // Use a Dynamic Type style
        lbl.font = UIFont.preferredFont(forTextStyle: .subheadline)
        lbl.adjustsFontForContentSizeCategory = true
        lbl.textColor = .secondaryLabel
        lbl.text = """
          • 8+ characters
          • 1 uppercase
          • 1 number
          • 1 special character
          """
        return lbl
    }()
    
    private func updateSignupButtonState() {
        let nameOK  = !(nameField.textField.text ?? "").isEmpty
        let emailOK = emailField.textField.text?.isValidEmail() ?? false
        let passOK  = passwordField.textField.text?.isValidPassword() ?? false
        
        signupButton.isEnabled = nameOK && emailOK && passOK
    }
    private func updatePasswordRequirementsUI() {
        guard let pw = passwordField.textField.text else { return }
        
        // Define each rule’s text + pass/fail
        let rules = [
            ("8+ characters",       pw.count >= 8),
            ("1 uppercase",         pw.range(of: "[A-Z]", options: .regularExpression) != nil),
            ("1 number",            pw.range(of: "\\d", options: .regularExpression) != nil),
            ("1 special character", pw.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil)
        ]
        
        let full = NSMutableAttributedString()
        // Choose a smaller Dynamic Type text style
        let textStyle: UIFont.TextStyle = .footnote
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        
        for (text, passed) in rules {
            let check = passed ? "✓" : "•"
            let color: UIColor = passed ? .systemGreen : .secondaryLabel
            // Scale the base Dynamic Type font
            let baseFont = UIFont.preferredFont(forTextStyle: textStyle)
            let font = metrics.scaledFont(for: baseFont)
            
            let piece = NSAttributedString(
                string: "\(check) \(text)\n",
                attributes: [
                    .foregroundColor: color,
                    .font: font
                ]
            )
            full.append(piece)
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
        if !NetworkMonitor.shared.isConnected {
            presentAlert(title: "No Internet Connection",
                         message: "Please check your network and try again.")
            return
        }

        let name     = nameField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email    = emailField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            presentAlert(title: "Missing Information", message: "Please fill out all fields.")
            return
        }

        setLoading(true)
        AuthService.register(email: email, password: password, name: name) { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)

            switch result {
            case .success:
                // ✅ Account exists and we asked Firebase to send the verification email.
                // Take the user to the verify screen.
                let vc = VerifyEmailViewController(email: email)
                self.navigationController?.pushViewController(vc, animated: true)

            case .failure(let error):
                let message: String
                switch error {
                case .weakPassword:
                    message = "Your password is too weak—please add uppercase letters, numbers, and special characters."
                case .emailAlreadyInUse:
                    message = "An account with this email already exists."
                case .networkError:
                    message = "Network error—please check your connection and try again."
                case .unknown(let description):
                    message = description
                default:
                    message = "Registration failed. Please try again."
                }
                self.presentAlert(title: "Registration Failed", message: message)
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
        }
        validationWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
}
