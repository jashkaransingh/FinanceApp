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

class BaseAuthViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Subclass configuration
    // Subclasses must set these in viewDidLoad before BaseAuth needs them.
    var primaryButton: PrimaryButton!
    var textFields: [AuthTextField] = []
    var loadingControls: [UIControl] = []
    private(set) var isLoading: Bool = false
    
    
    // MARK: - Private state
    fileprivate var currentNonce: String?
    private var originalButtonTitle: String?
    private var keyboardDidHideObserver: NSObjectProtocol?
    private let separatorHeight: CGFloat = 20
    private let socialButtonsHeight: CGFloat = 50
    private var separatorHeightConstraint: NSLayoutConstraint!
    private var socialButtonsHeightConstraint: NSLayoutConstraint!
    
    
    // MARK: - UI
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
    
    let formStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    private let separatorView = SeparatorView()
    
    private lazy var socialButtonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [appleSignInButton, googleSignInButton])
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var appleSignInButton = createSocialButton(logo: UIImage(systemName: "apple.logo"))
    lazy var googleSignInButton = createSocialButton(logo: UIImage(named: "google_logo"))
    
    private let offlineBanner: UILabel = {
        let lbl = UILabel()
        lbl.backgroundColor = .systemRed
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.text = "You’re Offline"
        lbl.font = UIFont.preferredFont(forTextStyle: .caption1)
        lbl.adjustsFontForContentSizeCategory = true
        lbl.isHidden = true
        return lbl
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        
        setupKeyboardDismissal()
        setupLayout()
        setupSocialButtonTargets()
        bindOfflineBanner()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        configureTextFieldNavigation()
        
        // Don’t steal focus if something is presented (alerts, sheets)
        guard presentedViewController == nil else { return }
        // Don’t refocus if a field is already focused
        guard view.findFirstResponder() == nil else { return }
        
        focusFirstFieldWhenSafe()
    }
    
    deinit {
        if let obs = keyboardDidHideObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        [offlineBanner, titleLabel, subtitleLabel, formStackView, separatorView, socialButtonsStack].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        separatorHeightConstraint = separatorView.heightAnchor.constraint(equalToConstant: separatorHeight)
        socialButtonsHeightConstraint = socialButtonsStack.heightAnchor.constraint(equalToConstant: socialButtonsHeight)
        
        NSLayoutConstraint.activate([
            offlineBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineBanner.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: offlineBanner.bottomAnchor, constant: 24),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            formStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            formStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            formStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            separatorView.topAnchor.constraint(equalTo: formStackView.bottomAnchor, constant: 20),
            separatorView.leadingAnchor.constraint(equalTo: formStackView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: formStackView.trailingAnchor),
            separatorHeightConstraint,
            
            socialButtonsStack.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 16),
            socialButtonsStack.leadingAnchor.constraint(equalTo: formStackView.leadingAnchor),
            socialButtonsStack.trailingAnchor.constraint(equalTo: formStackView.trailingAnchor),
            socialButtonsHeightConstraint,
        ])
    }
    func setSocialSectionHidden(_ hidden: Bool) {
        separatorView.isHidden = hidden
        socialButtonsStack.isHidden = hidden
        separatorHeightConstraint.constant = hidden ? 0 : separatorHeight
        socialButtonsHeightConstraint.constant = hidden ? 0 : socialButtonsHeight
    }
    
    
    // MARK: - Offline banner binding
    private func bindOfflineBanner() {
        // Initial state
        offlineBanner.isHidden = NetworkMonitor.shared.isConnected
        
        // Live updates
        NetworkMonitor.shared.onStatusChange = { [weak self] isConnected in
            self?.offlineBanner.isHidden = isConnected
        }
    }
    @discardableResult
    func guardOnlineOrAlert() -> Bool {
        if NetworkMonitor.shared.isConnected { return true }
        presentAlert(title: "No Internet Connection",
                     message: "Please check your network and try again.")
        return false
    }
    
    
    // MARK: - Keyboard + navigation helpers
    private func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    private func focusFirstFieldWhenSafe() {
        guard view.window != nil else { return }
        
        let focus = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.textFields.first?.textField.becomeFirstResponder()
            }
        }
        
        if let tc = transitionCoordinator {
            tc.animate(alongsideTransition: nil) { _ in focus() }
        } else {
            focus()
        }
    }
    
    func pushSmoothly(_ vc: UIViewController) {
        keyboardSafeTransition {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func popSmoothly() {
        keyboardSafeTransition {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func keyboardSafeTransition(_ action: @escaping () -> Void) {
        if view.findFirstResponder() != nil {
            view.endEditing(true)
            
            var didRun = false
            let runOnce: () -> Void = {
                guard !didRun else { return }
                didRun = true
                if let obs = self.keyboardDidHideObserver {
                    NotificationCenter.default.removeObserver(obs)
                    self.keyboardDidHideObserver = nil
                }
                action()
            }
            
            keyboardDidHideObserver = NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardDidHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                runOnce()
            }
            
            // Fallback so we never get stuck if notification doesn’t fire
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                runOnce()
            }
        } else {
            action()
        }
    }
    
    private func configureTextFieldNavigation() {
        for (idx, authTF) in textFields.enumerated() {
            let tf = authTF.textField
            tf.delegate = self
            tf.returnKeyType = (idx == textFields.count - 1) ? .done : .next
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let index = textFields.firstIndex(where: { $0.textField === textField }) else {
            textField.resignFirstResponder()
            return true
        }
        
        let nextIndex = index + 1
        if nextIndex < textFields.count {
            textFields[nextIndex].textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            primaryButton?.sendActions(for: .touchUpInside)
        }
        return true
    }
    
    @objc private func handleTapOutside() {
        view.endEditing(true)
    }
    
    // MARK: - Loading + alerts
    func setLoading(_ loading: Bool) {
        isLoading = loading
        DispatchQueue.main.async {
            if self.originalButtonTitle == nil {
                self.originalButtonTitle = self.primaryButton?.title(for: .normal)
            }
            
            let titleToShow = loading ? "Loading..." : (self.originalButtonTitle ?? "")
            self.primaryButton?.setTitle(titleToShow, for: .normal)
            
            self.primaryButton?.isEnabled = !loading
            self.appleSignInButton.isEnabled = !loading
            self.googleSignInButton.isEnabled = !loading
            self.textFields.forEach { $0.isUserInteractionEnabled = !loading }
            self.loadingControls.forEach { $0.isEnabled = !loading }
        }
    }
    
    func presentAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Social Sign-In
    private func setupSocialButtonTargets() {
        appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
    }
    
    private func createSocialButton(logo: UIImage?) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(logo, for: .normal)
        button.tintColor = .label
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 14
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return button
    }
    
    @objc private func handleAppleSignIn() {
        setLoading(true)
        
        guard let nonce = randomNonceString() else {
            setLoading(false)
            presentAlert(title: "Sign-In Error", message: "Unable to start Apple sign-in. Please try again.")
            return
        }
        
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    @objc private func handleGoogleSignIn() {
        setLoading(true)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
            guard let self else { return }
            
            if let error {
                self.setLoading(false)
                self.presentAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
                return
            }
            
            guard
                let result = signInResult,
                let idToken = result.user.idToken?.tokenString
            else {
                self.setLoading(false)
                self.presentAlert(title: "Google Sign-In Failed", message: "Could not retrieve Google ID token.")
                return
            }
            
            AuthService.signInWithGoogle(idToken: idToken) { [weak self] result in
                guard let self else { return }
                self.setLoading(false)
                
                switch result {
                case .success:
                    SceneDelegate.switchToMainApp()
                case .failure(let err):
                    let msg: String
                    switch err {
                    case .networkError:
                        msg = "No internet. Please try again."
                    default:
                        msg = err.localizedDescription
                    }
                    self.presentAlert(title: "Google Sign-In Error", message: msg)
                }
            }
        }
    }
    
    // MARK: - Crypto helpers
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess { return nil }
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

// MARK: - Apple Sign-In delegates
extension BaseAuthViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = view.window { return window }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce
        else {
            presentAlert(title: "Sign-In Error", message: "Invalid Apple Sign-In state.")
            return
        }
        
        setLoading(true)
        
        AuthService.signInWithApple(credential: appleIDCredential, nonce: nonce) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setLoading(false)
                self.currentNonce = nil
                
                switch result {
                case .success:
                    SceneDelegate.switchToMainApp()
                case .failure(let err):
                    let msg: String
                    switch err {
                    case .networkError:
                        msg = "No internet. Please try again."
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
        setLoading(false)
        currentNonce = nil
        presentAlert(title: "Apple Sign-In Failed", message: error.localizedDescription)
    }
}

extension BaseAuthViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.accessibilityIdentifier == "passwordVisibilityToggle" { return false }
        return true
    }
}

extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for sub in subviews {
            if let fr = sub.findFirstResponder() { return fr }
        }
        return nil
    }
}
