//
//  SettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/28/25.
//

import UIKit
import LocalAuthentication
import FirebaseAuth
import os

// MARK: - Main View Controller
class SettingsViewController: UIViewController {
    
    // MARK: - UI Properties
    private let viewModel = SettingsViewModel()
    private let gradientBackground = GradientBackgroundView()
    private let scrollView = UIScrollView()
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        return stackView
    }()
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "Settings")
    // This property will hold a reference to the profile card after it's created.
    private var profileCard: GlassCardView? {
        didSet {
            // Remove any old recognizers
            oldValue?.gestureRecognizers?.forEach { oldValue?.removeGestureRecognizer($0) }
            // Attach to the new card
            guard let card = profileCard else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(profileCardTapped))
            card.addGestureRecognizer(tap)
            card.isUserInteractionEnabled = true
        }
    }
    
    // --- UI Components ---
    private lazy var profileHeaderView = ProfileHeaderView()
    
    private lazy var appLockRow = SettingsRowView(
        icon: UIImage(systemName: "faceid"),
        iconBackgroundColor: .systemGreen,
        title: "App Lock",
        accessoryType: .aSwitch(
            isOn: UserDefaults.standard.bool(forKey: SettingsKeys.isAppLockEnabled),
            action: { [weak self] isOn in
                self?.handleAppLockToggled(wantsToEnable: isOn)
            }
        )
    )
    
    private lazy var bankConnectionsRow = SettingsRowView(icon: UIImage(systemName: "building.columns.fill"), iconBackgroundColor: .systemIndigo, title: "Bank Connections")
    private lazy var notificationsRow = SettingsRowView(icon: UIImage(systemName: "bell.badge.fill"), iconBackgroundColor: .systemRed, title: "Notifications")
    private lazy var appearanceRow = SettingsRowView(icon: UIImage(systemName: "moon.fill"), iconBackgroundColor: .systemPurple, title: "Appearance")
    
    private lazy var versionRow: SettingsRowView = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        
        return SettingsRowView(
            icon: UIImage(systemName: "info.circle.fill"),
            iconBackgroundColor: .systemGray,
            title: "Version",
            accessoryType: .detail("\(version)")
        )
    }()
    
    private lazy var termsRow = SettingsRowView(icon: UIImage(systemName: "doc.text.fill"), iconBackgroundColor: .systemGray2, title: "Terms of Service")
    private lazy var privacyRow = SettingsRowView(icon: UIImage(systemName: "hand.raised.fill"), iconBackgroundColor: .systemGray2, title: "Privacy Policy")
    
    private lazy var signOutRow: SettingsRowView = {
        let row = SettingsRowView(icon: nil, iconBackgroundColor: .clear, title: "Sign Out",  accessoryType: .centeredDestructive)
        row.setTextColor(.systemRed)
        return row
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = Design.Surface.page
        
        configureLayout()
        populateStackView()
        setupActions()
        bindViewModel()
        viewModel.loadData()
        applyOpaqueNavBarAppearance()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appLockRow.setSwitch(isOn: UserDefaults.standard.bool(forKey: SettingsKeys.isAppLockEnabled), animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientBackground.resumeAnimation()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gradientBackground.pauseAnimation()
    }

    
    // MARK: - Setup
    private func applyOpaqueNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Design.Surface.page
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .label
    }
    
    private func populateStackView() {
        let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
        let cardAppearance: GlassCardView.Appearance = isDarkMode ? .glass(dark: true, dimming: Design.Glass.cardDimming) : .solid
        
        // --- Profile Section ---
        let newProfileCard = GlassCardView(appearance: cardAppearance)
        if let userProfile = viewModel.userProfile {
            profileHeaderView.configure(with: userProfile)
            newProfileCard.isHidden = false
        } else {
            newProfileCard.isHidden = true
        }
        addRowsToCard(newProfileCard, rows: [profileHeaderView])
        
        mainStackView.addArrangedSubview(newProfileCard)
        self.profileCard = newProfileCard // Assign the newly created card to our property
        
        // --- General Section (Consolidated) ---
        mainStackView.addArrangedSubview(SectionHeaderLabel(title: "General"))
        let generalCard = GlassCardView(appearance: cardAppearance)
        addRowsToCard(generalCard,
                      rows: [ appLockRow,
                              makeDivider(),
                              bankConnectionsRow,
                              makeDivider(),
                              notificationsRow,
                              makeDivider(),
                              appearanceRow ])
        mainStackView.addArrangedSubview(generalCard)
        mainStackView.setCustomSpacing(32, after: generalCard)
        // --- About Section ---
        mainStackView.addArrangedSubview(SectionHeaderLabel(title: "About"))
        let aboutCard = GlassCardView(appearance: cardAppearance)
        addRowsToCard(aboutCard,
                      rows: [ versionRow,
                              makeDivider(),
                              termsRow,
                              makeDivider(),
                              privacyRow ])
        mainStackView.addArrangedSubview(aboutCard)
        
        // --- Sign Out Section ---
        let signOutCard = GlassCardView(appearance: cardAppearance)
        addRowsToCard(signOutCard, rows: [signOutRow])
        mainStackView.addArrangedSubview(signOutCard)
    }
    
    private func setupActions() {
        
        appLockRow.addTarget(self, action: #selector(appLockRowTapped), for: .touchUpInside)
        bankConnectionsRow.addTarget(self, action: #selector(bankConnectionsTapped), for: .touchUpInside)
        notificationsRow.addTarget(self, action: #selector(notificationsTapped), for: .touchUpInside)
        appearanceRow.addTarget(self, action: #selector(appearanceTapped), for: .touchUpInside)
        versionRow.addTarget(self, action: #selector(versionTapped), for: .touchUpInside)
        termsRow.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        privacyRow.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        signOutRow.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
    }
    
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        // Compute the new look
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let newAppearance: GlassCardView.Appearance = isDarkMode ? .glass(dark: true, dimming: Design.Glass.cardDimming) : .solid

        // Restyle existing cards in place (no flicker, no gesture re-wiring)
        for view in mainStackView.arrangedSubviews {
            (view as? GlassCardView)?.setAppearance(newAppearance)
        }
    }
    
    
    private func bindViewModel() {
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            self?.profileHeaderView.showLoadingState(isLoading)
        }
        viewModel.onProfileUpdate = { [weak self] profile in
            guard let self = self else { return }
            self.profileCard?.isHidden = false
            self.profileHeaderView.configure(with: profile)
        }
        viewModel.onFetchError = { [weak self] error in
            self?.log.error("Profile fetch failed: \(error.localizedDescription, privacy: .public)")
            self?.profileCard?.isHidden = true
        }
    }
    
    
    /// Helper function to add a set of rows to a card's content view using a UIStackView.
    private func addRowsToCard(_ card: GlassCardView, rows: [UIView]) {
        let stackView = UIStackView(arrangedSubviews: rows)
        stackView.axis = .vertical
        stackView.isUserInteractionEnabled = true
        
        card.contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: card.contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor),
        ])
    }
    
    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: Design.Hairline.width).isActive = true
        return v
    }
    
    // MARK: - Actions
    
    @objc private func profileCardTapped() {
        let vc = ProfileSettingsViewController(style: .insetGrouped)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @objc private func bankConnectionsTapped() {
        let vc = LinkedAccountsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func notificationsTapped() {
        let vc = NotificationsSettingsViewController(style: .insetGrouped)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func appearanceTapped() {
        let vc = AppearanceSettingsViewController(style: .insetGrouped)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func appLockRowTapped() {
        // Derive the desired next state from persisted truth, not from the switch UI.
        let wantsToEnable = !UserDefaults.standard.bool(forKey: SettingsKeys.isAppLockEnabled)
        handleAppLockToggled(wantsToEnable: wantsToEnable)
    }
    @objc private func versionTapped() {
        VersionInfoViewController.presentCompact(from: self)
    }


    
    private func configureLayout() {
        view.addSubview(gradientBackground)
        gradientBackground.alpha = Design.Alpha.gradientBackground
        gradientBackground.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        NSLayoutConstraint.activate([
            gradientBackground.topAnchor.constraint(equalTo: view.topAnchor),
            gradientBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 0),
            mainStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: 0),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            mainStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setAppLockInteraction(enabled: Bool) {
        appLockRow.isUserInteractionEnabled = enabled
        appLockRow.accessorySwitch.isEnabled = enabled
    }

    private func handleAppLockToggled(wantsToEnable: Bool) {
        setAppLockInteraction(enabled: false)
        let key = SettingsKeys.isAppLockEnabled

        if wantsToEnable {
            let context = LAContext()
            var error: NSError?

            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                presentAlert(title: "App Lock Unavailable",
                             message: error?.localizedDescription ?? "Please set up Face ID, Touch ID, or a passcode.")
                // Ensure truth + UI are OFF
                UserDefaults.standard.set(false, forKey: key)
                appLockRow.setSwitch(isOn: false, animated: true, sendEvent: false)
                setAppLockInteraction(enabled: true)
                return
            }

            context.evaluatePolicy(.deviceOwnerAuthentication,
                                   localizedReason: "Authenticate to enable App Lock") { [weak self] success, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if success {
                        UserDefaults.standard.set(true, forKey: key)
                        self.appLockRow.setSwitch(isOn: true, animated: true, sendEvent: false)
                    } else {
                        // Revert if user cancels / fails auth
                        UserDefaults.standard.set(false, forKey: key)
                        self.appLockRow.setSwitch(isOn: false, animated: true, sendEvent: false)
                    }
                    self.setAppLockInteraction(enabled: true)
                }
            }
        } else {
            // Turning OFF requires no authentication
            UserDefaults.standard.set(false, forKey: key)
            appLockRow.setSwitch(isOn: false, animated: true, sendEvent: false)
            setAppLockInteraction(enabled: true)
        }
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
    @objc private func termsTapped() {
        let vc = LegalTextViewController(document: .terms)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func privacyTapped() {
        let vc = LegalTextViewController(document: .privacy)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func signOutTapped() {
        let alert = UIAlertController(title: "Sign Out?", message: "You will be returned to the login screen.", preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Sign Out", style: .destructive) { _ in
            AuthService.signOut()
            SceneDelegate.switchToLogin()
        })
        if let pop = alert.popoverPresentationController { pop.sourceView = signOutRow; pop.sourceRect = signOutRow.bounds }
        present(alert, animated: true)
    }
    
    private class SectionHeaderLabel: UILabel {
        init(title: String) {
            super.init(frame: .zero)
            text = title
            font = UIFontMetrics(forTextStyle: .subheadline)
                .scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
            adjustsFontForContentSizeCategory = true

            textColor = .secondaryLabel
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}
