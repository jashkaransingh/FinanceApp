//
//  BaseAuthViewController.swift
//  Finance App
//
//  Created by Jas  on 7/19/25.
//

// In BaseAuthViewController.swift

import UIKit
import AuthenticationServices
import GoogleSignIn
import CryptoKit
import FirebaseCore

class BaseAuthViewController: UIViewController {
    
    // MARK: - Nonce for Apple Sign In
    fileprivate var currentNonce: String?
    
    // MARK: - Shared UI Properties
    let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "marble_background")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    let glassCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        return view
    }()
    
    let emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
    let passwordField = AuthTextField(icon: UIImage(systemName: "lock.fill"), isSecure: true)
    let separatorLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    lazy var appleSignInButton = createSocialButton(logo: UIImage(systemName: "apple.logo"))
    lazy var googleSignInButton = createSocialButton(logo: UIImage(named: "google_logo"))
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        setupSharedSubviews()
        setupSharedConstraints()
        setupSharedTargets()
    }
    
    // MARK: - Base Setup (Subclasses will call these)
    
    /// Configures the base navigation bar appearance.
    func configureNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = .label
        self.navigationController?.navigationBar.isHidden = (self is LoginViewController)
    }
    
    /// Adds all shared views to the view hierarchy. Subclasses can override to add more.
    func setupSharedSubviews() {
        emailField.textField.placeholder = "Email"
        passwordField.textField.placeholder = "Password"
        
        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(glassCard)
        
        guard let cardContentView = (glassCard.subviews.first as? UIVisualEffectView)?.contentView else { return }
        
        cardContentView.addSubview(emailField)
        cardContentView.addSubview(passwordField)
        cardContentView.addSubview(separatorLabel)
        cardContentView.addSubview(appleSignInButton)
        cardContentView.addSubview(googleSignInButton)
    }
    
    /// Sets up constraints for all shared views. Subclasses are responsible for their own constraints.
    func setupSharedConstraints() {
        // This helper function is defined below
        viewsToDisableAutoLayoutFor().forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: glassCard.topAnchor, constant: -24),
            
            glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            glassCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Social buttons are the same for both, so they can be constrained here
            appleSignInButton.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
            appleSignInButton.trailingAnchor.constraint(equalTo: googleSignInButton.leadingAnchor, constant: -12),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            googleSignInButton.topAnchor.constraint(equalTo: appleSignInButton.topAnchor),
            googleSignInButton.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
            googleSignInButton.widthAnchor.constraint(equalTo: appleSignInButton.widthAnchor),
            googleSignInButton.heightAnchor.constraint(equalTo: appleSignInButton.heightAnchor),
        ])
    }
    
    /// A helper for subclasses to provide all their views for Auto Layout setup.
    func viewsToDisableAutoLayoutFor() -> [UIView] {
        return [backgroundImageView, titleLabel, subtitleLabel, glassCard, emailField, passwordField, separatorLabel, appleSignInButton, googleSignInButton]
    }
    
    /// Connects targets for shared buttons. Subclasses should add their own.
    func setupSharedTargets() {
        appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
    }
    
    /// Factory method for creating social sign-in buttons.
    func createSocialButton(logo: UIImage?) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        
        config.image = logo
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        config.background.backgroundColor = .white.withAlphaComponent(0.8)
        config.background.cornerRadius = 14
        button.configuration = config
        button.tintColor = .label
        return button
    }
    
    // MARK: - Shared Actions (Apple & Google)
    @objc func handleAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @objc func handleGoogleSignIn() {
        // Implementation is identical for login and signup
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
                return
            }
            
            guard let result = signInResult, let idToken = result.user.idToken?.tokenString else {
                self.showAlert(title: "Google Sign-In Failed", message: "Could not retrieve Google ID Token.")
                return
            }
            
            self.setLoading(true) // Start loading *after* Google UI is dismissed
            AuthService.signInWithGoogle(idToken: idToken) { success in
                self.setLoading(false)
                if success {
                    SceneDelegate.switchToMainApp()
                } else {
                    self.showAlert(title: "Sign-In Failed", message: "An error occurred while signing in with Google.")
                }
            }
        }
    }
    
    // MARK: - Shared Helpers
    func setLoading(_ isLoading: Bool) {
        // Implementation will be slightly different for each subclass,
        // so we'll let them override it.
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Crypto Helpers for Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

// MARK: - Apple Sign-In Delegate Methods
extension BaseAuthViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                showAlert(title: "Apple Sign-In Failed", message: "Invalid state: A login callback was received without a nonce.")
                return
            }
            
            setLoading(true)
            AuthService.signInWithApple(credential: appleIDCredential, nonce: nonce) { [weak self] success in
                guard let self = self else { return }
                self.setLoading(false)
                if success {
                    SceneDelegate.switchToMainApp()
                } else {
                    self.showAlert(title: "Sign-In Failed", message: "An error occurred while signing in with Apple.")
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In failed with error: \(error.localizedDescription)")
        showAlert(title: "Apple Sign-In Failed", message: "An error occurred. Please try again.")
    }
}
