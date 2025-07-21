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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
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
        
        // Configure specific UI
        nameField.textField.placeholder = "Full Name"
        emailField.textField.placeholder = "Email"
        passwordField.textField.placeholder = "Password"
        
        // Assign components to base class properties for shared logic
        self.primaryButton = signupButton
        self.textFields = [nameField, emailField, passwordField]
    }

    private func setupLayout() {
        // Add specific components to the form stack view
        formStackView.addArrangedSubview(nameField)
        formStackView.addArrangedSubview(emailField)
        formStackView.addArrangedSubview(passwordField)
        formStackView.addArrangedSubview(signupButton)
        formStackView.setCustomSpacing(24, after: passwordField)
    }
    
    private func setupTargets() {
        signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleSignup() {
        guard let name = nameField.textField.text, !name.isEmpty,
              let email = emailField.textField.text, !email.isEmpty,
              let password = passwordField.textField.text, !password.isEmpty else {
            presentAlert(title: "Missing Information", message: "Please fill out all fields.")
            return
        }
        
        setLoading(true)
        AuthService.register(email: email, password: password, name: name) { [weak self] success in
            guard let self = self else { return }
            self.setLoading(false)
            if success {
                SceneDelegate.switchToMainApp()
            } else {
                self.presentAlert(title: "Registration Failed", message: "An error occurred during registration.")
            }
        }
    }
}

//import UIKit
//
// import AuthenticationServices
//
// import GoogleSignIn
//
// import CryptoKit
//
// import FirebaseCore
//
//
//
// class LoginViewController: UIViewController {
//
//      
//
//     // MARK: - Nonce for Apple Sign In
//
//     fileprivate var currentNonce: String?
//
//      
//
//     // MARK: - UI Properties
//
//     private let backgroundImageView: UIImageView = {
//
//         let imageView = UIImageView()
//
//         imageView.image = UIImage(named: "marble_background")
//
//         imageView.contentMode = .scaleAspectFill
//
//         return imageView
//
//     }()
//
//      
//
//     private let titleLabel: UILabel = {
//
//         let label = UILabel()
//
//         label.text = "Welcome Back"
//
//         label.font = .systemFont(ofSize: 32, weight: .bold)
//
//         label.textColor = .label
//
//         return label
//
//     }()
//
//      
//
//     private let subtitleLabel: UILabel = {
//
//         let label = UILabel()
//
//         label.text = "Start tracking your finances."
//
//         label.font = .systemFont(ofSize: 16, weight: .regular)
//
//         label.textColor = .secondaryLabel
//
//         return label
//
//     }()
//
//      
//
//     private let glassCard: UIView = {
//
//         let view = UIView()
//
//         view.backgroundColor = UIColor.white.withAlphaComponent(0.6)
//
//         view.layer.cornerRadius = 24
//
//         view.clipsToBounds = true
//
//          
//
//         let blurEffect = UIBlurEffect(style: .light)
//
//         let blurView = UIVisualEffectView(effect: blurEffect)
//
//         blurView.frame = view.bounds
//
//         blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//         view.addSubview(blurView)
//
//          
//
//         return view
//
//     }()
//
//      
//
//     private lazy var emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
//
//     private lazy var passwordField = AuthTextField(icon: UIImage(systemName: "lock.fill"), isSecure: true)
//
//     private let loginButton = PrimaryButton(title: "Log In")
//
//     private let forgotPasswordButton = LinkButton(title: "Forgot password?")
//
//     private let separatorLabel: UILabel = {
//
//         let label = UILabel()
//
//         label.text = "or"
//
//         label.font = .systemFont(ofSize: 12)
//
//         label.textColor = .secondaryLabel
//
//         label.textAlignment = .center
//
//         return label
//
//     }()
//
//     private lazy var appleSignInButton = createSocialButton(logo: UIImage(systemName: "apple.logo"))
//
//     private lazy var googleSignInButton = createSocialButton(logo: UIImage(named: "google_logo"))
//
//     private let switchToSignupButton = LinkButton(title: "Don't have an account? Sign up")
//
//      
//
//     // MARK: - Lifecycle
//
//     override func viewDidLoad() {
//
//         super.viewDidLoad()
//
//         self.navigationController?.navigationBar.isHidden = true
//
//         setupSubviews()
//
//         setupConstraints()
//
//         setupTargets()
//
//     }
//
//      
//
//     // MARK: - Setup
//
//     private func setupSubviews() {
//
//         emailField.textField.placeholder = "Email"
//
//         passwordField.textField.placeholder = "Password"
//
//         switchToSignupButton.setTitleColor(.secondaryLabel, for: .normal)
//
//         forgotPasswordButton.setTitleColor(.secondaryLabel, for: .normal)
//
//          
//
//         view.addSubview(backgroundImageView)
//
//         view.addSubview(titleLabel)
//
//         view.addSubview(subtitleLabel)
//
//         view.addSubview(glassCard)
//
//          
//
//         guard let cardContentView = (glassCard.subviews.first as? UIVisualEffectView)?.contentView else { return }
//
//          
//
//         cardContentView.addSubview(emailField)
//
//         cardContentView.addSubview(passwordField)
//
//         cardContentView.addSubview(forgotPasswordButton)
//
//         cardContentView.addSubview(loginButton)
//
//         cardContentView.addSubview(separatorLabel)
//
//         cardContentView.addSubview(appleSignInButton)
//
//         cardContentView.addSubview(googleSignInButton)
//
//          
//
//         view.addSubview(switchToSignupButton)
//
//     }
//
//      
//
//     private func setupConstraints() {
//
//         let allViews = [
//
//             backgroundImageView, titleLabel, subtitleLabel, glassCard,
//
//             emailField, passwordField, loginButton, forgotPasswordButton,
//
//             separatorLabel, appleSignInButton, googleSignInButton, switchToSignupButton
//
//         ]
//
//         allViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
//
//          
//
//         NSLayoutConstraint.activate([
//
//             backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
//
//             backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//
//             backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//
//             backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//              
//
//             titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//             titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),
//
//              
//
//             subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//             subtitleLabel.bottomAnchor.constraint(equalTo: glassCard.topAnchor, constant: -24),
//
//              
//
//             glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//
//             glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//
//             glassCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//
//              
//
//             // --- The Final, Corrected Constraint Chain ---
//
//             emailField.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 24),
//
//             emailField.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
//
//             emailField.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
//
//              
//
//             passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
//
//             passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
//
//             passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
//
//              
//
//             forgotPasswordButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 12),
//
//             forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),
//
//              
//
//             loginButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 12),
//
//             loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
//
//             loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
//
//              
//
//             separatorLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
//
//             separatorLabel.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
//
//             separatorLabel.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
//
//              
//
//             appleSignInButton.topAnchor.constraint(equalTo: separatorLabel.bottomAnchor, constant: 16),
//
//             appleSignInButton.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
//
//             appleSignInButton.trailingAnchor.constraint(equalTo: googleSignInButton.leadingAnchor, constant: -12),
//
//             appleSignInButton.heightAnchor.constraint(equalToConstant: 50),
//
//             appleSignInButton.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -24),
//
//              
//
//             googleSignInButton.topAnchor.constraint(equalTo: appleSignInButton.topAnchor),
//
//             googleSignInButton.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
//
//             googleSignInButton.widthAnchor.constraint(equalTo: appleSignInButton.widthAnchor),
//
//             googleSignInButton.heightAnchor.constraint(equalTo: appleSignInButton.heightAnchor),
//
//              
//
//             switchToSignupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//             switchToSignupButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
//
//         ])
//
//     }
//
//      
//
//     private func setupTargets() {
//
//         loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
//
//         forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
//
//         switchToSignupButton.addTarget(self, action: #selector(goToSignup), for: .touchUpInside)
//
//         appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
//
//         googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
//
//     }
//
//      
//
//     private func createSocialButton(logo: UIImage?) -> UIButton {
//
//         let button = UIButton(type: .system)
//
//         button.setImage(logo, for: .normal)
//
//         button.tintColor = .label
//
//         button.backgroundColor = .white.withAlphaComponent(0.8)
//
//         button.layer.cornerRadius = 14
//
//         button.imageView?.contentMode = .scaleAspectFit
//
//         button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
//
//         return button
//
//     }
//
//      
//
//     // MARK: - Actions
//
//     @objc private func handleLogin() {
//
//         guard let email = emailField.textField.text, !email.isEmpty,
//
//               let password = passwordField.textField.text, !password.isEmpty else {
//
//             presentAlert(title: "Missing Fields", message: "Please enter both email and password.")
//
//             return
//
//         }
//
//          
//
//         setLoading(true)
//
//         AuthService.signIn(email: email, password: password) { [weak self] success in
//
//             guard let self = self else { return }
//
//             self.setLoading(false)
//
//             if success {
//
//                 SceneDelegate.switchToMainApp()
//
//             } else {
//
//                 self.presentAlert(title: "Login Failed", message: "Please check your email and password.")
//
//             }
//
//         }
//
//     }
//
//      
//
//     @objc private func handleForgotPassword() {
//
//         let vc = ResetPasswordViewController()
//
//         navigationController?.pushViewController(vc, animated: true)
//
//     }
//
//      
//
//     @objc private func goToSignup() {
//
//         let vc = SignupViewController()
//
//         navigationController?.pushViewController(vc, animated: true)
//
//     }
//
//      
//
//     @objc private func handleAppleSignIn() {
//
//         let nonce = randomNonceString()
//
//         currentNonce = nonce
//
//         let appleIDProvider = ASAuthorizationAppleIDProvider()
//
//         let request = appleIDProvider.createRequest()
//
//         request.requestedScopes = [.fullName, .email]
//
//         request.nonce = sha256(nonce)
//
//          
//
//         let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//
//         authorizationController.delegate = self
//
//         authorizationController.presentationContextProvider = self
//
//         authorizationController.performRequests()
//
//     }
//
//      
//
//     @objc private func handleGoogleSignIn() {
//
//         setLoading(true)
//
//         GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
//
//             guard let self = self else { return }
//
//              
//
//             if let error = error {
//
//                 self.setLoading(false)
//
//                 self.presentAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
//
//                 return
//
//             }
//
//              
//
//             guard let result = signInResult,
//
//                   let idToken = result.user.idToken?.tokenString else {
//
//                 self.setLoading(false)
//
//                 self.presentAlert(title: "Google Sign-In Failed", message: "Could not retrieve Google ID token.")
//
//                 return
//
//             }
//
//              
//
//             AuthService.signInWithGoogle(idToken: idToken) { success in
//
//                 self.setLoading(false)
//
//                 if success {
//
//                     SceneDelegate.switchToMainApp()
//
//                 } else {
//
//                     self.presentAlert(title: "Google Sign-In Failed", message: "Could not sign in with Google. Please try again.")
//
//                 }
//
//             }
//
//         }
//
//     }
//
//      
//
//     // MARK: - Helpers
//
//      
//
//     private func setLoading(_ isLoading: Bool) {
//
//         DispatchQueue.main.async {
//
//             self.loginButton.isEnabled = !isLoading
//
//             self.appleSignInButton.isEnabled = !isLoading
//
//             self.googleSignInButton.isEnabled = !isLoading
//
//              
//
//             self.emailField.isUserInteractionEnabled = !isLoading
//
//             self.passwordField.isUserInteractionEnabled = !isLoading
//
//              
//
//             let buttonTitle = isLoading ? "Logging In..." : "Log In"
//
//             self.loginButton.setTitle(buttonTitle, for: .normal)
//
//         }
//
//     }
//
//      
//
//     private func presentAlert(title: String, message: String) {
//
//         DispatchQueue.main.async {
//
//             let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//             alert.addAction(.init(title: "OK", style: .default))
//
//             self.present(alert, animated: true)
//
//         }
//
//     }
//
//      
//
//     // MARK: - Crypto Helpers for Apple Sign-In
//
//      
//
//     private func randomNonceString(length: Int = 32) -> String {
//
//         precondition(length > 0)
//
//         let charset: [Character] =
//
//             Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//
//         var result = ""
//
//         var remainingLength = length
//
//          
//
//         while remainingLength > 0 {
//
//             let randoms: [UInt8] = (0 ..< 16).map { _ in
//
//                 var random: UInt8 = 0
//
//                 let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//
//                 if errorCode != errSecSuccess {
//
//                     fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
//
//                 }
//
//                 return random
//
//             }
//
//              
//
//             randoms.forEach { random in
//
//                 if remainingLength == 0 {
//
//                     return
//
//                 }
//
//                  
//
//                 if random < charset.count {
//
//                     result.append(charset[Int(random)])
//
//                     remainingLength -= 1
//
//                 }
//
//             }
//
//         }
//
//          
//
//         return result
//
//     }
//
//      
//
//     private func sha256(_ input: String) -> String {
//
//         let inputData = Data(input.utf8)
//
//         let hashedData = SHA256.hash(data: inputData)
//
//         let hashString = hashedData.compactMap {
//
//             String(format: "%02x", $0)
//
//         }.joined()
//
//          
//
//         return hashString
//
//     }
//
// }
//
//
//
// // MARK: - Apple Sign-In Delegate Methods
//
// extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//
//      
//
//     func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//
//         return self.view.window!
//
//     }
//
//      
//
//     func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//
//         if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//
//             guard let nonce = currentNonce else {
//
//                 fatalError("Invalid state: A login callback was received, but no nonce was stored.")
//
//             }
//
//              
//
//             setLoading(true)
//
//             AuthService.signInWithApple(credential: appleIDCredential, nonce: nonce) { [weak self] success in
//
//                 guard let self = self else { return }
//
//                 self.setLoading(false)
//
//                 if success {
//
//                     SceneDelegate.switchToMainApp()
//
//                 } else {
//
//                     self.presentAlert(title: "Apple Sign-In Failed", message: "Could not sign in with Apple. Please try again.")
//
//                 }
//
//             }
//
//         }
//
//     }
//
//      
//
//     func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//
//         print("Sign in with Apple failed: \(error.localizedDescription)")
//
//         setLoading(false)
//
//         presentAlert(title: "Apple Sign-In Failed", message: error.localizedDescription)
//
//     }
//
// }
//
//
//
//import UIKit
//
// import AuthenticationServices
//
// import GoogleSignIn
//
// import CryptoKit // Needed for Apple Sign-In nonce
//
// import FirebaseCore
//
//
//
// class SignupViewController: UIViewController {
//
//
//
//     // MARK: - Nonce for Apple Sign In
//
//     // Stored property to hold the nonce during the Apple Sign-In flow.
//
//     fileprivate var currentNonce: String?
//
//
//
//     // MARK: - UI Properties
//
//     private let backgroundImageView: UIImageView = {
//
//         let imageView = UIImageView()
//
//         imageView.image = UIImage(named: "marble_background")
//
//         imageView.contentMode = .scaleAspectFill
//
//         return imageView
//
//     }()
//
//
//
//     private let titleLabel: UILabel = {
//
//         let label = UILabel()
//
//         label.text = "Create Account"
//
//         label.font = .systemFont(ofSize: 32, weight: .bold)
//
//         label.textColor = .label
//
//         return label
//
//     }()
//
//
//
//     private let subtitleLabel: UILabel = {
//
//         let label = UILabel()
//
//         label.text = "Start tracking your finances."
//
//         label.font = .systemFont(ofSize: 16, weight: .regular)
//
//         label.textColor = .secondaryLabel
//
//         return label
//
//     }()
//
//
//
//     private let glassCard: UIView = {
//
//         let view = UIView()
//
//         view.backgroundColor = UIColor.white.withAlphaComponent(0.6)
//
//         view.layer.cornerRadius = 24
//
//         view.clipsToBounds = true
//
//
//
//         let blurEffect = UIBlurEffect(style: .light)
//
//         let blurView = UIVisualEffectView(effect: blurEffect)
//
//         blurView.frame = view.bounds
//
//         blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//         view.addSubview(blurView)
//
//
//
//         return view
//
//     }()
//
//
//
//     private lazy var nameField = AuthTextField(icon: UIImage(systemName: "person.fill"))
//
//     private lazy var emailField = AuthTextField(icon: UIImage(systemName: "envelope.fill"))
//
//     private lazy var passwordField = AuthTextField(icon: UIImage(systemName: "lock.fill"), isSecure: true)
//
//     private let signupButton = PrimaryButton(title: "Create Account")
//
//     private let separatorLabel: UILabel = {
//
//         let label = UILabel()
//
//         label.text = "or"
//
//         label.font = .systemFont(ofSize: 12)
//
//         label.textColor = .secondaryLabel
//
//         label.textAlignment = .center
//
//         return label
//
//     }()
//
//     private lazy var appleSignInButton = createSocialButton(logo: UIImage(systemName: "apple.logo"))
//
//     private lazy var googleSignInButton = createSocialButton(logo: UIImage(named: "google_logo"))
//
//
//
//     // MARK: - Lifecycle
//
//     override func viewDidLoad() {
//
//         super.viewDidLoad()
//
//         // Make the navigation bar transparent to show the background
//
//         self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//
//         self.navigationController?.navigationBar.shadowImage = UIImage()
//
//         self.navigationController?.navigationBar.isTranslucent = true
//
//         self.navigationController?.navigationBar.tintColor = .label // Ensures back button is visible
//
//          
//
//         setupSubviews()
//
//         setupConstraints()
//
//         setupTargets()
//
//     }
//
//
//
//     // MARK: - Setup
//
//     private func setupSubviews() {
//
//         nameField.textField.placeholder = "Full Name"
//
//         emailField.textField.placeholder = "Email"
//
//         passwordField.textField.placeholder = "Password"
//
//          
//
//         view.addSubview(backgroundImageView)
//
//         view.addSubview(titleLabel)
//
//         view.addSubview(subtitleLabel)
//
//         view.addSubview(glassCard)
//
//
//
//         guard let cardContentView = (glassCard.subviews.first as? UIVisualEffectView)?.contentView else { return }
//
//          
//
//         cardContentView.addSubview(nameField)
//
//         cardContentView.addSubview(emailField)
//
//         cardContentView.addSubview(passwordField)
//
//         cardContentView.addSubview(signupButton)
//
//         cardContentView.addSubview(separatorLabel)
//
//         cardContentView.addSubview(appleSignInButton)
//
//         cardContentView.addSubview(googleSignInButton)
//
//     }
//
//
//
//     private func setupConstraints() {
//
//         let allViews = [
//
//             backgroundImageView, titleLabel, subtitleLabel, glassCard,
//
//             nameField, emailField, passwordField, signupButton,
//
//             separatorLabel, appleSignInButton, googleSignInButton
//
//         ]
//
//         allViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
//
//
//
//         NSLayoutConstraint.activate([
//
//             backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
//
//             backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//
//             backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//
//             backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//
//
//             titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//             titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),
//
//
//
//             subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//             subtitleLabel.bottomAnchor.constraint(equalTo: glassCard.topAnchor, constant: -24),
//
//
//
//             glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//
//             glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//
//             glassCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//
//
//
//             // --- Constraint chain inside the card ---
//
//             nameField.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 24),
//
//             nameField.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
//
//             nameField.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
//
//
//
//             emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
//
//             emailField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
//
//             emailField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
//
//              
//
//             passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
//
//             passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
//
//             passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
//
//              
//
//             signupButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 24),
//
//             signupButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
//
//             signupButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
//
//              
//
//             separatorLabel.topAnchor.constraint(equalTo: signupButton.bottomAnchor, constant: 20),
//
//             separatorLabel.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
//
//             separatorLabel.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
//
//              
//
//             appleSignInButton.topAnchor.constraint(equalTo: separatorLabel.bottomAnchor, constant: 16),
//
//             appleSignInButton.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
//
//             appleSignInButton.trailingAnchor.constraint(equalTo: googleSignInButton.leadingAnchor, constant: -12),
//
//             appleSignInButton.heightAnchor.constraint(equalToConstant: 50),
//
//             appleSignInButton.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -24),
//
//
//
//             googleSignInButton.topAnchor.constraint(equalTo: appleSignInButton.topAnchor),
//
//             googleSignInButton.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
//
//             googleSignInButton.widthAnchor.constraint(equalTo: appleSignInButton.widthAnchor),
//
//             googleSignInButton.heightAnchor.constraint(equalTo: appleSignInButton.heightAnchor),
//
//         ])
//
//     }
//
//
//
//     private func setupTargets() {
//
//         signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
//
//         appleSignInButton.addTarget(self, action: #selector(handleAppleSignUp), for: .touchUpInside)
//
//         googleSignInButton.addTarget(self, action: #selector(handleGoogleSignUp), for: .touchUpInside)
//
//     }
//
//
//
//     private func createSocialButton(logo: UIImage?) -> UIButton {
//
//         let button = UIButton(type: .system)
//
//         button.setImage(logo, for: .normal)
//
//         button.tintColor = .label
//
//         button.backgroundColor = .white.withAlphaComponent(0.8)
//
//         button.layer.cornerRadius = 14
//
//         button.imageView?.contentMode = .scaleAspectFit
//
//         button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
//
//         return button
//
//     }
//
//      
//
//     // MARK: - Actions
//
//      
//
//     @objc private func handleSignup() {
//
//         guard let name = nameField.textField.text, !name.isEmpty,
//
//               let email = emailField.textField.text, !email.isEmpty,
//
//               let password = passwordField.textField.text, !password.isEmpty else {
//
//             showAlert(title: "Missing Information", message: "Please fill out all fields.")
//
//             return
//
//         }
//
//          
//
//         setLoading(true)
//
//         AuthService.register(email: email, password: password, name: name) { [weak self] success in
//
//             guard let self = self else { return }
//
//             self.setLoading(false)
//
//             if success {
//
//                 print("✅ Successfully registered user and created profile.")
//
//                 SceneDelegate.switchToMainApp()
//
//             } else {
//
//                 self.showAlert(title: "Registration Failed", message: "An error occurred during registration. Please try again.")
//
//             }
//
//         }
//
//     }
//
//      
//
//     @objc private func handleAppleSignUp() {
//
//         let nonce = randomNonceString()
//
//         currentNonce = nonce
//
//         let appleIDProvider = ASAuthorizationAppleIDProvider()
//
//         let request = appleIDProvider.createRequest()
//
//         request.requestedScopes = [.fullName, .email]
//
//         request.nonce = sha256(nonce)
//
//
//
//         let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//
//         authorizationController.delegate = self
//
//         authorizationController.presentationContextProvider = self
//
//         authorizationController.performRequests()
//
//     }
//
//      
//
//     @objc private func handleGoogleSignUp() {
//
//             setLoading(true)
//
//             // The GIDConfiguration is already set in the AppDelegate.
//
//             // We just need to call the signIn method with the presenting view controller.
//
//              
//
//             GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
//
//                 guard let self = self else { return }
//
//                  
//
//                 if let error = error {
//
//                     self.setLoading(false)
//
//                     self.showAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
//
//                     return
//
//                 }
//
//
//
//                 guard let result = signInResult,
//
//                       let idToken = result.user.idToken?.tokenString else {
//
//                     self.setLoading(false)
//
//                     self.showAlert(title: "Google Sign-In Failed", message: "Could not retrieve Google ID Token.")
//
//                     return
//
//                 }
//
//                  
//
//                 AuthService.signInWithGoogle(idToken: idToken) { success in
//
//                     self.setLoading(false)
//
//                     if success {
//
//                         print("✅ Successfully signed in with Google.")
//
//                         SceneDelegate.switchToMainApp()
//
//                     } else {
//
//                         self.showAlert(title: "Sign-In Failed", message: "An error occurred while signing in with Google.")
//
//                     }
//
//                 }
//
//             }
//
//         }
//
//      
//
//     // MARK: - Helpers
//
//      
//
//     private func setLoading(_ isLoading: Bool) {
//
//         DispatchQueue.main.async {
//
//             self.signupButton.isEnabled = !isLoading
//
//             self.appleSignInButton.isEnabled = !isLoading
//
//             self.googleSignInButton.isEnabled = !isLoading
//
//              
//
//             self.nameField.isUserInteractionEnabled = !isLoading
//
//             self.emailField.isUserInteractionEnabled = !isLoading
//
//             self.passwordField.isUserInteractionEnabled = !isLoading
//
//              
//
//             let buttonTitle = isLoading ? "Creating Account..." : "Create Account"
//
//             self.signupButton.setTitle(buttonTitle, for: .normal)
//
//         }
//
//     }
//
//
//
//     private func showAlert(title: String, message: String) {
//
//         DispatchQueue.main.async {
//
//             let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//             alert.addAction(UIAlertAction(title: "OK", style: .default))
//
//             self.present(alert, animated: true)
//
//         }
//
//     }
//
//      
//
//     // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
//
//     private func randomNonceString(length: Int = 32) -> String {
//
//         precondition(length > 0)
//
//         let charset: [Character] =
//
//             Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//
//         var result = ""
//
//         var remainingLength = length
//
//
//
//         while remainingLength > 0 {
//
//             let randoms: [UInt8] = (0 ..< 16).map { _ in
//
//                 var random: UInt8 = 0
//
//                 let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//
//                 if errorCode != errSecSuccess {
//
//                     fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
//
//                 }
//
//                 return random
//
//             }
//
//
//
//             randoms.forEach { random in
//
//                 if remainingLength == 0 {
//
//                     return
//
//                 }
//
//
//
//                 if random < charset.count {
//
//                     result.append(charset[Int(random)])
//
//                     remainingLength -= 1
//
//                 }
//
//             }
//
//         }
//
//         return result
//
//     }
//
//      
//
//     private func sha256(_ input: String) -> String {
//
//         let inputData = Data(input.utf8)
//
//         let hashedData = SHA256.hash(data: inputData)
//
//         let hashString = hashedData.compactMap {
//
//             String(format: "%02x", $0)
//
//         }.joined()
//
//         return hashString
//
//     }
//
// }
//
//
//
// // MARK: - ASAuthorizationControllerDelegate & PresentationContextProviding
//
// extension SignupViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//
//      
//
//     func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//
//         return self.view.window!
//
//     }
//
//      
//
//     func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//
//         if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//
//             guard let nonce = currentNonce else {
//
//                 showAlert(title: "Apple Sign-In Failed", message: "Invalid state: A login callback was received without a nonce.")
//
//                 return
//
//             }
//
//              
//
//             setLoading(true)
//
//             AuthService.signInWithApple(credential: appleIDCredential, nonce: nonce) { [weak self] success in
//
//                 guard let self = self else { return }
//
//                 self.setLoading(false)
//
//                 if success {
//
//                     print("✅ Successfully signed in with Apple.")
//
//                     SceneDelegate.switchToMainApp()
//
//                 } else {
//
//                     self.showAlert(title: "Sign-In Failed", message: "An error occurred while signing in with Apple.")
//
//                 }
//
//             }
//
//         }
//
//     }
//
//
//
//     func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//
//         // Handle error.
//
//         print("Apple Sign-In failed with error: \(error.localizedDescription)")
//
//         showAlert(title: "Apple Sign-In Failed", message: "An error occurred. Please try again.")
//
//     }
//
// }
