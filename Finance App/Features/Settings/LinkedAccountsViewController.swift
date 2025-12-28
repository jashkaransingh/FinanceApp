//
//  LinkedAccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class LinkedAccountsViewController: UIViewController {

    // MARK: - Background
    private let gradientBackground = GradientBackgroundView()

    // MARK: – State
    private var isAccountLinked: Bool = false
    
    // MARK: – Bank name
    private var bankName: String? { didSet { applyBankName() } }

    private let bankTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        return l
    }()

    // MARK: - UI
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let emptyStateView: EmptyStateView = {
        let v = EmptyStateView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Card shown when an account is linked
    private let connectedCard = GlassCardView(
        appearance: UITraitCollection.current.userInterfaceStyle == .dark
            ? .glass(dark: true, dimming: Design.Glass.cardDimming)
            : .solid
    )
    private let statusPill = PaddingLabel(insets: .init(top: 3, left: 8, bottom: 3, right: 8))
    private let replaceButton = UIButton(type: .system)
    private let unlinkButton  = UIButton(type: .system)
    
    private func applyBankName() {
        let trimmed = bankName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = trimmed.isEmpty ? "Bank Account" : trimmed
        bankTitleLabel.text = title
        bankTitleLabel.accessibilityLabel = "Bank: \(title)"
    }


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Linked Accounts" // keep this for now; change to “Bank Connection” if you prefer
        view.backgroundColor = Design.Surface.page

        // Background gradient
        view.addSubview(gradientBackground)
        gradientBackground.alpha = Design.Alpha.gradientBackground
        gradientBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gradientBackground.topAnchor.constraint(equalTo: view.topAnchor),
            gradientBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gradientBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        setupConnectedCard()
        setupEmptyStateView()
        setupActivityIndicator()

        // Initial visibility
        connectedCard.isHidden = true
        emptyStateView.isHidden = true
        activityIndicator.hidesWhenStopped = true

        // Empty state copy
        emptyStateView.configure(
            message: "Link a bank to import transactions automatically.",
            buttonTitle: "Link a Bank"
        )
        emptyStateView.setAction(self, action: #selector(addOrReplaceAccount), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchLinkStatus()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientBackground.resumeAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gradientBackground.pauseAnimation()
    }

    // MARK: - UI Setup

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupEmptyStateView() {
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    private func setupConnectedCard() {
        view.addSubview(connectedCard)
        connectedCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectedCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Design.Space.md),
            connectedCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Design.Space.md),
            connectedCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Design.Space.md)
        ])

        // Content container
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = Design.Space.sm
        content.translatesAutoresizingMaskIntoConstraints = false
        connectedCard.contentView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: connectedCard.contentView.topAnchor, constant: Design.Space.sm),
            content.leadingAnchor.constraint(equalTo: connectedCard.contentView.leadingAnchor, constant: Design.Space.sm),
            content.trailingAnchor.constraint(equalTo: connectedCard.contentView.trailingAnchor, constant: -Design.Space.sm),
            content.bottomAnchor.constraint(equalTo: connectedCard.contentView.bottomAnchor, constant: -Design.Space.sm)
        ])

        // Top Row: icon • titles • spacer • pill
        // Icon “chip”
        let iconBox = UIView()
        iconBox.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.12)
        iconBox.layer.cornerRadius = Design.Radius.row
        iconBox.layer.cornerCurve = Design.cornerCurve
        iconBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconBox.widthAnchor.constraint(equalToConstant: 40),
            iconBox.heightAnchor.constraint(equalToConstant: 40)
        ])

        let icon = UIImageView(image: UIImage(systemName: "building.columns.fill"))
        icon.preferredSymbolConfiguration = .init(textStyle: .body, scale: .medium)
        icon.tintColor = .systemIndigo
        icon.contentMode = .center
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBox.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor)
        ])

        // Labels
        applyBankName()

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Secured by Plaid"
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel

        let labels = UIStackView(arrangedSubviews: [bankTitleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2

        // Status pill
        statusPill.text = "Connected"
        statusPill.font = .systemFont(ofSize: 12, weight: .semibold)
        statusPill.textColor = .systemGreen
        statusPill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        statusPill.layer.cornerRadius = 10
        statusPill.layer.masksToBounds = true
        statusPill.setContentHuggingPriority(.required, for: .horizontal)
        statusPill.setContentCompressionResistancePriority(.required, for: .horizontal)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let topRow = UIStackView(arrangedSubviews: [iconBox, labels, spacer, statusPill])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = Design.Space.md
        content.addArrangedSubview(topRow)

        // Button row: Replace • Unlink (compact)
        // Replace Bank — slightly larger, less rounded
        var replaceCfg = UIButton.Configuration.filled()
        replaceCfg.title = "Replace Bank"
        replaceCfg.baseForegroundColor = .white
        replaceCfg.baseBackgroundColor = .systemBlue

        // Less curve than .capsule (use .medium if you want even squarer)
        replaceCfg.cornerStyle = .large

        // A bit bigger (height driven by top/bottom insets + font size)
        replaceCfg.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)

        var titleAttrs = AttributeContainer()
        titleAttrs.font = .systemFont(ofSize: 16, weight: .semibold)   // bump from 15 → 16
        replaceCfg.attributedTitle = AttributedString("Replace Bank", attributes: titleAttrs)

        replaceButton.configuration = replaceCfg
        replaceButton.addTarget(self, action: #selector(addOrReplaceAccount), for: .touchUpInside)

        var unlinkCfg = UIButton.Configuration.plain()
        unlinkCfg.title = "Unlink"
        unlinkCfg.baseForegroundColor = .systemRed
        unlinkButton.configuration = unlinkCfg
        unlinkButton.addTarget(self, action: #selector(unlinkTapped), for: .touchUpInside)

        // keep buttons close to each other
        let buttons = UIStackView(arrangedSubviews: [replaceButton, unlinkButton])
        buttons.axis = .horizontal
        buttons.alignment = .center
        buttons.spacing = Design.Space.md               // e.g. 12–16
        content.addArrangedSubview(buttons)

        connectedCard.isHidden = true
    }

    // MARK: - UI Toggle
    private func updateUI() {
        activityIndicator.stopAnimating()
        connectedCard.isHidden = !isAccountLinked
        emptyStateView.isHidden = isAccountLinked
    }

    // MARK: – Data
    private func fetchLinkStatus() {
        // Show loading spinner immediately
        connectedCard.isHidden = true
        emptyStateView.isHidden = true
        activityIndicator.startAnimating()

        guard let uid = Auth.auth().currentUser?.uid else {
            self.isAccountLinked = false
            self.bankName = nil            // ← keep title default when signed out
            self.updateUI()
            return
        }

        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] doc, error in
            guard let self = self else { return }
            if let error = error {
                self.activityIndicator.stopAnimating()
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }

            if let data = doc?.data(), doc!.exists {
                self.isAccountLinked = data["isBankConnected"] as? Bool ?? false
                self.bankName       = data["bankName"] as? String   // ← NEW: pull the bank name
            } else {
                self.isAccountLinked = false
                self.bankName = nil                                  // ← NEW: reset to default title
            }

            self.updateUI()
        }
    }

    // MARK: – Actions

    private func unlinkAccount() {
        // Flip UI immediately
        isAccountLinked = false
        updateUI()

        // Fire actual unlink
        PlaidService.shared.unlinkAccount { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    guard let uid = Auth.auth().currentUser?.uid else {
                        NotificationCenter.default.post(name: .bankAccountUnlinked, object: nil)
                        return
                    }

                    let docRef = Firestore.firestore().collection("users").document(uid)
                    docRef.setData([
                        "isBankConnected": false,
                        "bankName": FieldValue.delete(),
                        "accountSummaries": FieldValue.delete()
                    ], merge: true) { _ in
                        NotificationCenter.default.post(name: .bankAccountUnlinked, object: nil)
                    }
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(.init(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func unlinkTapped() {
        let alert = UIAlertController(
            title: "Unlink Bank?",
            message: "Transactions will stop syncing. You can link a bank again anytime.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Unlink", style: .destructive) { [weak self] _ in
            self?.unlinkAccount()
        })
        present(alert, animated: true)
    }


    @objc private func addOrReplaceAccount() {
        startPlaidLinkFlow()
    }

    private func startPlaidLinkFlow() {
        PlaidService.shared.startPlaidLink(
            from: self,
            onSuccess: { [weak self] _ in
                guard let self = self else { return }
                NotificationCenter.default.post(name: .bankAccountLinked, object: nil)
                self.fetchLinkStatus()
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                print("Plaid Link flow failed: \(error)")
            }
        )
    }
}




