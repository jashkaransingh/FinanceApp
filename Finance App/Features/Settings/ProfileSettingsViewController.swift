//
//  ProfileSettingsViewController.swift
//  Finance App
//
//  Created by Jas  on 8/19/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ProfileSettingsViewController: UITableViewController {
    
    // MARK: - Background + Card
    private let gradientBackground = GradientBackgroundView()
    private let headerCard = GlassCardView(
        appearance: UITraitCollection.current.userInterfaceStyle == .dark
        ? .glass(dark: true, dimming: Design.Glass.cardDimming)
        : .solid
    )
    
    // MARK: - Form
    private let formView = ProfileFormView()
    private var headerContainer: UIView?            // <- new: reuse header container
    private var deleteFooterContainer: UIView?
    private var initialVerified: Bool = false
    private var didLayoutOnce = false
    
    // MARK: - State
    private var initialName: String = ""
    private var initialEmail: String = ""
    private var isEditingProfile = false
    
    // MARK: - Nav items
    private lazy var editItem   = UIBarButtonItem(title: "Edit",   style: .plain, target: self, action: #selector(startEditing))
    private lazy var saveItem   = UIBarButtonItem(title: "Save",   style: .done,  target: self, action: #selector(saveTapped))
    private lazy var cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
    
    // MARK: - Simple name cache (for instant paint)
    private let nameCacheKey = "profile.name.cache"
    private func cacheName(_ name: String) { UserDefaults.standard.set(name, forKey: nameCacheKey) }
    private func loadCachedName() -> String? { UserDefaults.standard.string(forKey: nameCacheKey) }
    
    // MARK: - Lifecycle
    override init(style: UITableView.Style) { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Account"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = editItem
        
        view.backgroundColor = Design.Surface.page
        tableView.backgroundColor = Design.Surface.page
        gradientBackground.backgroundColor = Design.Surface.page
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.backgroundView = gradientBackground
        gradientBackground.alpha = Design.Alpha.gradientBackground
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        mountHeaderIfNeeded()           // mount once
        buildHeader()                   // paint immediately, refresh in background
        installKeyboardDismissTap()
        installDeleteFooter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientBackground.resumeAnimation()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gradientBackground.pauseAnimation()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        let isDark = traitCollection.userInterfaceStyle == .dark
        headerCard.setAppearance(isDark ? .glass(dark: true, dimming: Design.Glass.cardDimming) : .solid)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didLayoutOnce else { return }
        didLayoutOnce = true
        // Now that insets are final, size header & footer before first paint
        tableView.relayoutTableHeaderIfNeeded(noAnimation: true)
        relayoutDeleteFooterToBottom(noAnimation: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        didLayoutOnce = false
    }
    
    
    // MARK: - Header (mount once)
    private func mountHeaderIfNeeded() {
        guard headerContainer == nil else { return }
        
        // Add formView into card
        headerCard.contentView.subviews.forEach { $0.removeFromSuperview() }
        headerCard.contentView.addSubview(formView)
        formView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            formView.topAnchor.constraint(equalTo: headerCard.contentView.topAnchor),
            formView.leadingAnchor.constraint(equalTo: headerCard.contentView.leadingAnchor),
            formView.trailingAnchor.constraint(equalTo: headerCard.contentView.trailingAnchor),
            formView.bottomAnchor.constraint(equalTo: headerCard.contentView.bottomAnchor)
        ])
        
        // Size the tableHeaderView via a container
        let container = UIView()
        container.addSubview(headerCard)
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: container.topAnchor, constant: Design.Space.md),      // 16
            headerCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Design.Space.md),
            headerCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Design.Space.md),
            headerCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Design.Space.md)
        ])
        container.layoutIfNeeded()
        let target = CGSize(width: tableView.bounds.width,
                            height: UIView.layoutFittingCompressedSize.height)
        container.frame.size.width = target.width
        container.frame.size.height = container.systemLayoutSizeFitting(target).height
        
        
        tableView.tableHeaderView = container
        headerContainer = container
        
        // Handlers
        formView.onChangePassword = { [weak self] in
            guard let self = self else { return }

            let emailFromForm = self.formView.email
            let prefill = emailFromForm.isEmpty ? Auth.auth().currentUser?.email : emailFromForm
            let vc = ResetPasswordViewController(mode: .inApp, prefillEmail: prefill)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Paint now, refresh later
    private func applyHeader(name: String, email: String, verified: Bool) {
        initialName  = name
        initialEmail = email
        initialVerified = verified
        formView.configure(name: name, email: email, isEmailVerified: verified)
        if !isEditingProfile { formView.setEditing(false) }
        
        // Keep header/footers in sync if content height changed
        tableView.relayoutTableHeaderIfNeeded(noAnimation: true)
        relayoutDeleteFooterToBottom(noAnimation: true)
    }
    
    
    
    private func buildHeader() {
        guard let user = Auth.auth().currentUser else { return }
        
        // 1) Paint immediately from what we already have (Auth or cache)
        let emailNow = user.email ?? ""
        let nameNow  = (user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        ?? loadCachedName()
        ?? ""
        applyHeader(name: nameNow, email: emailNow, verified: true)
        
        // 2) Background refresh (cache → server). No blocking.
        let doc = Firestore.firestore().collection("users").document(user.uid)
        
        // Try Firestore cache first (fast, offline)
        doc.getDocument(source: .cache) { [weak self] snap, _ in
            guard let self = self else { return }
            if let cached = snap?.data()?["name"] as? String, !cached.isEmpty, cached != self.initialName {
                self.applyHeader(name: cached, email: emailNow, verified: true)
                self.cacheName(cached)
            }
            
            // Then remote server
            doc.getDocument { [weak self] snap, _ in
                guard let self = self else { return }
                if let remote = snap?.data()?["name"] as? String, !remote.isEmpty, remote != self.initialName {
                    self.applyHeader(name: remote, email: emailNow, verified: true)
                    self.cacheName(remote)
                }
            }
        }
        
        // Optional: refresh email verification in the background
        user.reload { [weak self] _ in
            guard let self = self else { return }
            self.applyHeader(name: self.initialName, email: emailNow, verified: true)
        }
    }
    
    // MARK: - Delete footer
    private func installDeleteFooter() {
        let container = UIView()
        container.backgroundColor = .clear
        deleteFooterContainer = container
        
        let button = UIButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.title = "Delete Account"
        cfg.baseForegroundColor = .systemRed
        cfg.contentInsets = .init(top: 16, leading: 12, bottom: 16, trailing: 12)
        button.configuration = cfg
        button.backgroundColor = Design.Surface.card
        button.layer.cornerCurve = Design.cornerCurve
        button.heightAnchor.constraint(equalToConstant: Design.Row.height).isActive = true
        button.layer.cornerRadius = Design.Radius.capsule // 16 – matches GlassCardView
        button.layer.borderWidth = 0
        button.layer.masksToBounds = true
        button.layer.borderColor = Design.Hairline.color.cgColor
        
        button.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        let vstack = UIStackView(arrangedSubviews: [spacer, button])
        vstack.axis = .vertical
        vstack.spacing = 12
        vstack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Design.Space.md),   // 16
            vstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Design.Space.md),
            vstack.topAnchor.constraint(equalTo: container.topAnchor, constant: Design.Space.sm),          // 12 (keeps a little air)
            vstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Design.Space.md),
            
        ])
        
        container.frame.size.height = 96
        UIView.performWithoutAnimation {
            self.tableView.tableFooterView = container
        }
        relayoutDeleteFooterToBottom(noAnimation: true)
    }
    
    @objc private func deleteAccountTapped() {
        navigationController?.pushViewController(DeleteAccountViewController(), animated: true)
    }
    
    // MARK: - Edit / Save / Cancel
    @objc private func startEditing() {
        isEditingProfile = true
        navigationItem.leftBarButtonItem = cancelItem
        navigationItem.rightBarButtonItem = saveItem
        formView.setEditing(true)
        updateSaveEnabled()
    }
    
    @objc private func cancelTapped() {
        formView.configure(name: initialName, email: initialEmail, isEmailVerified: true)
        isEditingProfile = false
        formView.setEditing(false)
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = editItem
        updateSaveEnabled()
    }
    
    private func updateSaveEnabled() {
        guard isEditingProfile else { saveItem.isEnabled = false; return }
        saveItem.isEnabled = formView.name != initialName && !formView.name.isEmpty
    }
    
    @objc private func saveTapped() {
        view.endEditing(true)
        let newName = formView.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else {
            presentAlert(title: "Check your details", message: "Please enter a valid name.")
            return
        }
        saveItem.isEnabled = false
        
        guard let user = Auth.auth().currentUser else { return }
        let change = user.createProfileChangeRequest()
        change.displayName = newName
        
        change.commitChanges { [weak self] err in
            guard let self = self else { return }
            if let err = err {
                self.presentAlert(title: "Couldn’t save", message: err.localizedDescription)
                self.updateSaveEnabled()
                return
            }
            
            // Keep Firestore in sync
            let userDoc = Firestore.firestore().collection("users").document(user.uid)
            userDoc.setData(["name": newName], merge: true) { err in
                if let err = err {
                    self.presentAlert(title: "Couldn’t save", message: err.localizedDescription)
                    self.saveItem.isEnabled = true
                    return
                }
                self.cacheName(newName)
                user.reload { _ in
                    DispatchQueue.main.async {
                        self.initialName = newName
                        self.toast("Saved")
                        self.isEditingProfile = false
                        self.formView.setEditing(false)
                        self.navigationItem.leftBarButtonItem = nil
                        self.navigationItem.rightBarButtonItem = self.editItem
                        self.updateSaveEnabled()
                        self.buildHeader()
                    }
                }
            }
        }
    }
    
    private func relayoutDeleteFooterToBottom(noAnimation: Bool = false) {
        guard let footer = deleteFooterContainer else { return }
        
        let visibleHeight = tableView.bounds.height
        - tableView.adjustedContentInset.top
        - tableView.adjustedContentInset.bottom
        let headerHeight = tableView.tableHeaderView?.frame.height ?? 0
        let needed = max(96, visibleHeight - headerHeight)
        
        guard abs(footer.frame.height - needed) > 0.5 else { return }
        
        let apply = { [weak self] in
            guard let self = self else { return }
            footer.frame.size.height = needed
            self.tableView.tableFooterView = footer
            self.tableView.layoutIfNeeded()
        }
        noAnimation ? UIView.performWithoutAnimation(apply) : apply()
    }
    
    
    // MARK: - Minimal table (header only)
    override func numberOfSections(in tableView: UITableView) -> Int { 0 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    
    // MARK: - Utils
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func installKeyboardDismissTap() {
        let g = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        g.cancelsTouchesInView = false
        tableView.addGestureRecognizer(g)
    }
    @objc private func endEditingTap() { view.endEditing(true) }
    
    private func toast(_ text: String) {
        let label = PaddingLabel(insets: .init(top: 6, left: 10, bottom: 6, right: 10))
        label.text = text
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .footnote)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        UIView.animate(withDuration: 0.2, animations: { label.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.25, delay: 1.0, options: [], animations: { label.alpha = 0 }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}

// MARK: - Helpers
final class PaddingLabel: UILabel {
    let insets: UIEdgeInsets
    init(insets: UIEdgeInsets) { self.insets = insets; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return .init(width: s.width + insets.left + insets.right,
                     height: s.height + insets.top + insets.bottom)
    }
}

private extension UITableView {
    func relayoutTableHeaderIfNeeded(noAnimation: Bool = false) {
        guard let header = tableHeaderView else { return }
        
        header.setNeedsLayout()
        header.layoutIfNeeded()
        
        let size = header.systemLayoutSizeFitting(
            CGSize(width: bounds.width,
                   height: UIView.layoutFittingCompressedSize.height)
        )
        
        guard header.frame.height != size.height else { return }
        
        let apply = { [weak self] in
            guard let self = self else { return }
            header.frame.size.height = size.height
            self.tableHeaderView = header
            self.layoutIfNeeded()
        }
        noAnimation ? UIView.performWithoutAnimation(apply) : apply()
    }
}

