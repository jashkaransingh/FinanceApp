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
import Network

// MARK: - BaseAuthViewController
class BaseAuthViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    fileprivate var currentNonce: String?
    private var originalButtonTitle: String?
    
    // To be configured by subclasses
    var primaryButton: PrimaryButton!
    var textFields: [AuthTextField] = []
    
    // MARK: - Common UI Components
    let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "marble_background")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Start tracking your finances."
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()
    
    let glassCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        return view
    }()
    
    // StackView to hold form elements (email, password, buttons)
    // Subclasses will add their specific views to this stack.
    let formStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    private let separatorLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    private let offlineBanner: UILabel = {
        let lbl = UILabel()
        lbl.backgroundColor = .systemRed
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.text = "You’re Offline"
        lbl.font = UIFont.preferredFont(forTextStyle: .caption1)
        lbl.adjustsFontForContentSizeCategory = true
        lbl.isHidden = true   // start hidden
        return lbl
    }()
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "OfflineBannerMonitor")
    
    lazy var appleSignInButton = createSocialButton(logo: UIImage(systemName: "apple.logo"))
    lazy var googleSignInButton = createSocialButton(logo: UIImage(named: "google_logo"))
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: — Keyboard Dismissal
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapOutside))
        tap.cancelsTouchesInView = false      // so buttons still work
        tap.delegate = self
        view.addGestureRecognizer(tap)
        setupCommonUI()
        setupCommonConstraints()
        setupSocialButtonTargets()
        setupOfflineBanner()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // wire up Next/Done
        configureTextFieldNavigation()
        // Autofocus
        textFields.first?.textField.becomeFirstResponder()
    }
    
    
    private func configureTextFieldNavigation() {
        for (idx, authTF) in textFields.enumerated() {
            let tf = authTF.textField
            tf.delegate = self
            tf.returnKeyType = (idx == textFields.count - 1) ? .done : .next
        }
    }
    
    // MARK: - Common Setup
    private func setupCommonUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(glassCard)
        
        guard let cardContentView = (glassCard.subviews.first as? UIVisualEffectView)?.contentView else { return }
        
        let socialButtonsStack = UIStackView(arrangedSubviews: [appleSignInButton, googleSignInButton])
        socialButtonsStack.spacing = 12
        socialButtonsStack.distribution = .fillEqually
        
        cardContentView.addSubview(formStackView)
        cardContentView.addSubview(separatorLabel)
        cardContentView.addSubview(socialButtonsStack)
        
        [backgroundImageView, titleLabel, subtitleLabel, glassCard, formStackView, separatorLabel, socialButtonsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupCommonConstraints() {
        guard let socialButtonsStack = googleSignInButton.superview else { return }
        
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
            glassCard.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            // --- Constraints inside the card ---
            formStackView.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 24),
            formStackView.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 20),
            formStackView.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -20),
            
            separatorLabel.topAnchor.constraint(equalTo: formStackView.bottomAnchor, constant: 20),
            separatorLabel.leadingAnchor.constraint(equalTo: formStackView.leadingAnchor),
            separatorLabel.trailingAnchor.constraint(equalTo: formStackView.trailingAnchor),
            
            socialButtonsStack.topAnchor.constraint(equalTo: separatorLabel.bottomAnchor, constant: 16),
            socialButtonsStack.leadingAnchor.constraint(equalTo: formStackView.leadingAnchor),
            socialButtonsStack.trailingAnchor.constraint(equalTo: formStackView.trailingAnchor),
            socialButtonsStack.heightAnchor.constraint(equalToConstant: 50),
            socialButtonsStack.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupSocialButtonTargets() {
        appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
    }
    private func setupOfflineBanner() {
        // 1) Add banner above everything else
        view.addSubview(offlineBanner)
        offlineBanner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            offlineBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineBanner.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 2) Watch for network changes
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                // Show banner if no connection, hide if connected
                self?.offlineBanner.isHidden = (path.status == .satisfied)
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    
    // MARK: - Social Sign-In Actions
    @objc private func handleAppleSignIn() {
        setLoading(true)
        // Attempt to generate a secure nonce
        guard let nonce = randomNonceString() else {
            setLoading(false)
            presentAlert(
                title: "Sign-In Error",
                message: "Unable to start Apple sign-in. Please try again."
            )
            return
        }
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
    
    @objc private func handleGoogleSignIn() {
        // Show loading state immediately
        setLoading(true)
        
        // Kick off Google Sign-In
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.setLoading(false)
                self.presentAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
                return
            }
            
            guard
                let result = signInResult,
                let idToken = result.user.idToken?.tokenString
            else {
                self.setLoading(false)
                self.presentAlert(title: "Google Sign-In Failed",
                                  message: "Could not retrieve Google ID token.")
                return
            }
            
            // Now hand off to your AuthService
            AuthService.signInWithGoogle(idToken: idToken) { [weak self] result in
                guard let self = self else { return }
                self.setLoading(false)
                
                switch result {
                case .success:
                    SceneDelegate.switchToMainApp()
                    
                case .failure(let err):
                    let msg: String
                    switch err {
                    case .networkError:
                        msg = "No internet – please try again."
                    default:
                        msg = err.localizedDescription
                    }
                    self.presentAlert(title: "Google Sign-In Error", message: msg)
                }
            }
        }
    }
    
    @objc private func handleTapOutside() {
        view.endEditing(true)
    }
    
    // MARK: - Helpers
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            // 1) Capture the button’s title the *first* time we go into loading
            if self.originalButtonTitle == nil {
                self.originalButtonTitle = self.primaryButton?.title(for: .normal)
            }
            
            // 2) Decide which title to show
            let titleToShow = loading
            ? "Loading..."
            : (self.originalButtonTitle ?? "")
            
            // 3) Apply the title and enable/disable
            self.primaryButton?.setTitle(titleToShow, for: .normal)
            self.primaryButton?.isEnabled = !loading
            self.appleSignInButton.isEnabled = !loading
            self.googleSignInButton.isEnabled = !loading
            self.textFields.forEach { $0.isUserInteractionEnabled = !loading }
        }
    }
    
    
    func presentAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func createSocialButton(logo: UIImage?) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(logo, for: .normal)
        button.tintColor = .label
        button.backgroundColor = .white.withAlphaComponent(0.8)
        button.layer.cornerRadius = 14
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return button
    }
    
    // MARK: - Crypto Helpers
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                // Failed to generate secure random byte
                return nil
            }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
        return result
    }
    
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign-In Delegate
extension BaseAuthViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Safely unwrap the hosting window for the sign-in sheet.
        if let window = self.view.window {
            return window
        }
        // Fallback to key window if for some reason view.window is nil
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
        ?? UIWindow()
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce else {
            presentAlert(
                title: "Sign-In Error",
                message: "Invalid Apple Sign-In state."
            )
            return
        }
        
        // Show loading state
        setLoading(true)
        
        guard
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            setLoading(false)
            presentAlert(
                title: "Sign-In Error",
                message: "Could not verify Apple credentials. Please try again."
            )
            return
        }
        
        AuthService.signInWithApple(
            credential: appleIDCredential,
            nonce: nonce
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Stop loading & clear nonce
                self.setLoading(false)
                self.currentNonce = nil
                
                switch result {
                case .success:
                    SceneDelegate.switchToMainApp()
                    
                case .failure(let err):
                    let msg: String
                    switch err {
                    case .networkError:
                        msg = "No internet – please try again."
                    case .userNotFound:
                        msg = "No account found for this Apple ID."
                    default:
                        msg = err.localizedDescription
                    }
                    self.presentAlert(title: "Apple Sign-In Error", message: msg)
                }
            }
        }
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple failed: \(error.localizedDescription)")
        setLoading(false)
        currentNonce = nil
        presentAlert(title: "Apple Sign-In Failed", message: error.localizedDescription)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let index = textFields.firstIndex(where: { $0.textField === textField }) else {
            textField.resignFirstResponder()
            return true
        }
        
        let nextIndex = index + 1
        if nextIndex < textFields.count {
            // Move to the next field
            textFields[nextIndex].textField.becomeFirstResponder()
        } else {
            // Last field: dismiss keyboard and trigger the primary action
            textField.resignFirstResponder()
            primaryButton?.sendActions(for: .touchUpInside)
        }
        return true
    }
}

extension BaseAuthViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // We check if the view that was tapped has the identifier we set.
        if touch.view?.accessibilityIdentifier == "passwordVisibilityToggle" {
            // If it's our button, don't let the main tap gesture fire.
            return false
        }
        // For all other views, let the gesture fire as normal.
        return true
    }
}
