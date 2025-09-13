//
//  VerifyEmailViewController.swift
//  Finance App
//
//  Created by Jas  on 8/28/25.
//

import UIKit
import FirebaseAuth

final class VerifyEmailViewController: BaseAuthViewController {

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.textColor = .secondaryLabel
        l.font = .preferredFont(forTextStyle: .body)
        return l
    }()

    private let checkButton = PrimaryButton(title: "I’ve Verified")
    private let resendButton = LinkButton(title: "Resend verification email")
    private let email: String
    private var isBusy = false

    // MARK: - Init
    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Verify your email"
        subtitleLabel.text = nil

        // BaseAuth wiring
        self.primaryButton = checkButton
        self.textFields = [] // none

        messageLabel.text = """
        We sent a verification link to:
        \(email)

        Tap the link in your email, then come back and press “I’ve Verified”.
        """

        // Layout inside the card
        formStackView.addArrangedSubview(messageLabel)
        formStackView.addArrangedSubview(checkButton)
        formStackView.setCustomSpacing(12, after: checkButton)
        formStackView.addArrangedSubview(resendButton)

        checkButton.addTarget(self,  action: #selector(didTapCheck),  for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(didTapResend), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func didTapCheck() {
        guard !isBusy else { return }
        isBusy = true
        checkButton.isEnabled = false
        resendButton.isEnabled = false

        setLoading(true)
        guard let user = Auth.auth().currentUser else {
            onMain {
                self.setLoading(false)
                self.presentAlert(title: "Please Log In", message: "Your session ended. Sign in and then verify.")
                SceneDelegate.switchToLogin()
            }
            return
        }

        user.reload { [weak self] error in
            guard let self = self else { return }
            onMain {
                self.setLoading(false)
                self.isBusy = false
                self.checkButton.isEnabled = true
                self.resendButton.isEnabled = true
                
                if let error = error {
                    self.handleReloadError(error)
                    return
                }
                if Auth.auth().currentUser?.isEmailVerified == true {
                    SharedDataManager.shared.reloadUserProfile { _ in
                        onMain { SceneDelegate.switchToMainApp() }
                    }
                } else {
                    self.presentAlert(
                        title: "Not Verified Yet",
                        message: "Tap the link in your email, then try again."
                    )
                }
            }
        }
    }

    @objc private func didTapResend() {
        guard !isBusy else { return }
        isBusy = true
        checkButton.isEnabled = false
        resendButton.isEnabled = false
        
        setLoading(true)
        guard Auth.auth().currentUser != nil else {
            onMain {
                self.setLoading(false)
                self.presentAlert(title: "Please Log In", message: "Your session ended. Sign in and then request a new link.")
                SceneDelegate.switchToLogin()
            }
            return
        }

        AuthService.sendVerificationEmail { [weak self] result in
            guard let self = self else { return }
            onMain {
                self.setLoading(false)
                self.isBusy = false
                    self.checkButton.isEnabled = true
                    self.resendButton.isEnabled = true
                switch result {
                case .success:
                    self.presentAlert(title: "Email Sent",
                                      message: "Check your inbox (and spam) for a new verification link.")
                case .failure(let error):
                    self.presentAlert(title: "Couldn’t Send",
                                      message: VerifyEmailViewController.errorMessage(for: error))
                }
            }
        }
    }

    private static func errorMessage(for error: AuthService.AuthError) -> String {
        switch error {
        case .networkError:
            return "Network issue. Please try again."
        case .unknown(let msg):
            return msg
        default:
            return "We couldn’t send the email. Please try again shortly."
        }
    }
    
    private func handleReloadError(_ error: Error) {
        let nsError = error as NSError
        let authError = AuthErrorCode(_bridgedNSError: nsError)   // wraps the NSError

        switch authError?.code {
        case .networkError:
            presentAlert(title: "Network Issue", message: "We couldn’t reach the server. Please try again.")

        case .userTokenExpired, .requiresRecentLogin:
            presentAlert(title: "Please Log In Again", message: "Your session expired. Sign in and then verify.")
            SceneDelegate.switchToLogin()

        case .userNotFound:
            presentAlert(title: "Account Not Found", message: "Please sign in again to continue.")
            SceneDelegate.switchToLogin()

        case .tooManyRequests:
            presentAlert(title: "Too Many Attempts", message: "Please wait a bit and try again.")

        default:
            presentAlert(title: "Something Went Wrong", message: "Please try again shortly.")
        }
    }
}

