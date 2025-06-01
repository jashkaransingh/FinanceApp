//
//  SignupViewController.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

class SignupViewController: UIViewController {
    
    private let emailField = CustomTextField(placeholder: "Email")
    private let passwordField = CustomTextField(placeholder: "Password", isSecure: true)
    private let signupButton = PrimaryButton(title: "Sign Up")
    private let nameField = CustomTextField(placeholder: "Full Name")


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Sign Up"
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
            [nameField, emailField, passwordField, signupButton].forEach {
                view.addSubview($0)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
        }
    
    private func setupConstraints() {
            NSLayoutConstraint.activate([
                
                nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
                nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                
                emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
                emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                
                passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
                passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
                passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
                
                signupButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 24),
                signupButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
                signupButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor)
            ])
        }
    
    @objc private func handleSignup() {
        guard
            let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        else { return }

        AuthService.register(email: email, password: password, name: name) { success in
            if success {
                SceneDelegate.switchToMainApp()
            } else {
                self.presentAlert(title: "Signup Failed", message: "Please try again.")
            }
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }


}
