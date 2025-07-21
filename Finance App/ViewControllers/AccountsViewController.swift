//
//  AccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import LinkKit
import FirebaseAuth
import FirebaseFirestore

class AccountsViewController: UIViewController {
    
    // MARK: - UI Properties
    private let headerView = TitleHeaderView()
    private let scrollView = UIScrollView()
    private let stackView  = UIStackView()
    private let refreshControl = UIRefreshControl()
    
    // MARK: – Data Properties
    private var summaries: [AccountSummary] = []
    var needsRefresh = true // Tracks whether we need to re-fetch the cards
    private var placeholderButton: UIButton?
    private var isLoading = false
    
    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        // Hide the stock nav bar so custom header can sit under the status bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        configureHeader()
        configureScrollView()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        scrollView.addSubview(refreshControl)
        configureStackView()
        configureFloatingButton()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        if needsRefresh {
            fetchData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // When leaving this screen, restore the nav bar for downstream VCs
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: – UI Configuration
    private func configureHeader() {
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,   constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        headerView.onProfileTap = { [weak self] in
            self?.openProfile()
        }
    }
    
    private func configureScrollView() {
        view.addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func configureStackView() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func configureFloatingButton() {
        let fab = FloatingActionButton()
        view.addSubview(fab)
        
        NSLayoutConstraint.activate([
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        fab.addTarget(self, action: #selector(didTapBudgetAssistant), for: .touchUpInside)
    }
    
    // MARK: – Skeleton & Placeholder
    private func showSkeletonCards() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for _ in 0..<3 {
            let skeleton = ShimmerView()
            skeleton.translatesAutoresizingMaskIntoConstraints = false
            skeleton.heightAnchor.constraint(equalToConstant: 140).isActive = true
            stackView.addArrangedSubview(skeleton)
        }
    }
    
    private func makeConnectButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("Connect Your Bank", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 10
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.systemBlue.cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 200).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }
    
    // MARK: – Data Loading
    
    @objc private func refreshData() {
        fetchData()
    }
    
    private func fetchData() {
        isLoading = true
        showSkeletonCards()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            showPlaceholder(message: "Please sign in.")
            return
        }
        
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists else {
                self?.showPlaceholder(message: "An error occurred.")
                self?.refreshControl.endRefreshing()
                return
            }
            
            let isBankConnected = document.data()?["isBankConnected"] as? Bool ?? false
            if isBankConnected {
                self.loadSummaries()
            } else {
                self.showPlaceholder(message: "Connect your bank to get started.")
            }
        }
    }
    
    private func loadSummaries() {
        placeholderButton?.removeFromSuperview()
        placeholderButton = nil
        stackView.alignment = .fill
        
        DataService.loadSummaries { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            self.needsRefresh = false
            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            switch result {
            case .success(let summaries):
                self.summaries = summaries
                self.populateCards()
                HapticsManager.trigger(.medium)
            case .failure(let error):
                print("❌ Failed to load summaries:", error)
                self.showPlaceholder(message: "Could not load accounts.")
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    private func showPlaceholder(message: String) {
        isLoading = false
        needsRefresh = false
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        placeholderButton?.removeFromSuperview()
        refreshControl.endRefreshing()
        
        let button = makeConnectButton()
        button.setTitle(message, for: .normal)
        button.addTarget(self, action: #selector(startPlaidLinkFlow), for: .touchUpInside)
        placeholderButton = button
        
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }
    
    // MARK: – UI Population
    private func populateCards() {
        summaries.forEach { model in
            let card = AccountCardView()
            card.configure(with: model)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 140).isActive = true
            card.addTarget(self, action: #selector(cardTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(card)
        }
    }
    
    // MARK: – Actions
    @objc private func didTapBudgetAssistant() {
        let vc = BudgetAssistantViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func startPlaidLinkFlow() {
        PlaidService.shared.startPlaidLink(from: self, onSuccess: { [weak self] in
            // On success, we just need to refresh the view.
            self?.needsRefresh = true
            self?.fetchData()
        }, onError: { error in
            print("❌ Plaid Link flow failed: \(error)")
            if case .sessionExpired = error {
                SceneDelegate.switchToLogin()
            }
        })
    }
    
    @objc private func cardTapped(_ card: AccountCardView) {
        guard let model = card.model else { return }
        
        HapticsManager.trigger(.light)
        
        let detailVC = AccountDetailViewController()
        detailVC.period = {
            if model.periodTitle.contains("Today")  { return "today" }
            if model.periodTitle.contains("Week")   { return "week"  }
            if model.periodTitle.contains("Month")  { return "month" }
            return "today"
        }()
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc private func openProfile() {
        HapticsManager.trigger(.selection)
        let settingsVC = SettingsViewController(style: .insetGrouped)
        navigationController?.pushViewController(settingsVC, animated: true)
    }
}

// === Data Flow ===
// 1. First Run / No Bank Linked:
//    - The "Connect Your Bank" button is shown.
//    - User taps it → startPlaidLinkFlow() is called.
//    - PlaidService handles the link_token and public_token exchange.
//    - On success, the view is refreshed → fetchData() is called again.
//
// 2. Bank Linked:
//    - fetchData() checks Firestore and sees the bank is connected.
//    - loadSummaries() is called → fetches account data from the backend.
//    - Account cards are displayed.
//    - The Floating Action Button (+) opens the Budget Assistant.
