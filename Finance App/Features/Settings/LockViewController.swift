//
//  LockViewController.swift
//  Finance App
//
//  Created by Jas  on 7/2/25.
//

import UIKit
import LocalAuthentication

final class LockViewController: UIViewController {
    
    // Add a property to hold the retry button
    private var retryButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Use a blur effect to obscure the app content behind it
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark) // A modern blur style
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        
        let iconView = UIImageView()
            let context = LAContext()
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                let iconName = context.biometryType == .faceID ? "faceid" : "touchid"
                iconView.image = UIImage(systemName: iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 64))
            }
            iconView.tintColor = .white.withAlphaComponent(0.5)
            
            view.addSubview(iconView)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Trigger authentication as soon as the lock screen is visible
        authenticateWithBiometrics()
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        let reason = "Unlock with Face ID or Touch ID."
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            print("Biometrics not available.")
            // In a real app, you might show an alert here.
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // On success, dismiss the lock screen
                    self?.dismiss(animated: true)
                } else {
                    // On failure, show a "Try Again" button instead of creating a loop.
                    self?.showRetryButton()
                }
            }
        }
    }
    
    /// Creates and displays a button to allow the user to manually retry authentication.
    private func showRetryButton() {
        retryButton?.removeFromSuperview() // Remove old button if it exists
        
        let button = UIButton(type: .system)
        button.setTitle("Try Again", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        self.retryButton = button
    }
    
    /// Called when the retry button is tapped.
    @objc private func retryTapped() {
        retryButton?.removeFromSuperview()
        retryButton = nil
        authenticateWithBiometrics()
    }
}
