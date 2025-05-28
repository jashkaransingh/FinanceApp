//
//  LoginViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

class LoginViewController: UIViewController {
    
    private let emailField = CustomTextField(placeholder: "Email")
    private let passwordField = CustomTextField(placeholder: "Password", isSecure: true)
    private let loginButton = PrimaryButton(title: "Log In")
    private let switchToSignupButton = LinkButton(title: "Don't have an account? Sign up")
    private let forgotPasswordButton = LinkButton(title: "Forgot password?")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Log In"
        setupSubviews()
        setupConstraints()
        
    }
    
    private func setupSubviews() {
        [emailField, passwordField, forgotPasswordButton, loginButton, switchToSignupButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        switchToSignupButton.addTarget(self, action: #selector(goToSignup), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(goToResetPassword), for: .touchUpInside)

        
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            emailField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),
            
            loginButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            
            switchToSignupButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            switchToSignupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    
    @objc private func handleLogin() {
        guard let emailRaw = emailField.text,
              let passwordRaw = passwordField.text else { return }
        
        let email = emailRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        AuthService.signIn(email: email, password: password) { success in
            if success {
                SceneDelegate.switchToMainApp()
            } else {
                self.presentAlert(title: "Login Failed", message: "Please check your email and password.")
            }
        }
    }
    
    @objc private func handleForgotPassword() {
        let alert = UIAlertController(title: "Reset Password",
                                      message: "Enter your email to receive a reset link.",
                                      preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { _ in
            guard let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !email.isEmpty else {
                self.presentAlert(title: "Error", message: "Please enter a valid email.")
                return
            }

            AuthService.resetPassword(email: email) { success in
                if success {
                    self.presentAlert(title: "Sent", message: "A reset link has been sent to your email.")
                } else {
                    self.presentAlert(title: "Failed", message: "Unable to send reset link. Try again later.")
                }
            }
        }))

        present(alert, animated: true)
    }

    @objc private func goToResetPassword() {
        let resetVC = ResetPasswordViewController()
        navigationController?.pushViewController(resetVC, animated: true)
    }

    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    @objc private func goToSignup() {
        navigationController?.pushViewController(SignupViewController(), animated: true)
    }
    
}
