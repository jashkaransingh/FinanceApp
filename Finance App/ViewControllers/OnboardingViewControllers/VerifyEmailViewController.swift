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
        setLoading(true)
        Auth.auth().currentUser?.reload(completion: { [weak self] _ in
            guard let self = self else { return }
            self.setLoading(false)
            if Auth.auth().currentUser?.isEmailVerified == true {
                // Optional: refresh your profile cache, then go in
                SharedDataManager.shared.reloadUserProfile { _ in
                    SceneDelegate.switchToMainApp()
                }
            } else {
                self.presentAlert(title: "Not Verified Yet",
                                  message: "We haven’t received confirmation. Please tap the link in the email, then try again.")
            }
        })
    }

    @objc private func didTapResend() {
        setLoading(true)
        AuthService.sendVerificationEmail { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)

            switch result {
            case .success:
                self.presentAlert(
                    title: "Email Sent",
                    message: "Check your inbox (and spam) for a new verification link."
                )

            case .failure(let error):
                self.presentAlert(
                    title: "Couldn’t Send",
                    message: VerifyEmailViewController.errorMessage(for: error)
                )
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

}

