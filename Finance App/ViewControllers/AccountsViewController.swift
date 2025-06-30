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
    private let headerView = TitleHeaderView()// 'My Accounts' header at top
    private let scrollView = UIScrollView()// Scrollable area for cards
    private let stackView  = UIStackView()// Vertical stack inside scrollView
    
    // MARK: – Data Properties
    private var summaries: [AccountSummary] = []//list of account summaries (fetched from backend)
    var needsRefresh = true// Tracks whether we need to re‐fetch the cards
    private var placeholderButton: UIButton?// If no accounts exist yet, we show a placeholder “Connect Bank” button
    private var isLoading = false
    
    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        // Hide the stock nav bar so custom header can sit under the status bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        configureHeader()
        configureScrollView()
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
    private func configureHeader() {// Configures and constrains the custom headerView.
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,   constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44) // match native nav-bar height
        ])
    }
    
    private func setupActions() {
        headerView.onProfileTap = { [weak self] in
            self?.openProfile()
        }
        
        headerView.onDropdownTap = {
            // e.g. show your account‐picker dropdown
            print("Header tapped – menu should open now")
        }
    }
    
    private func configureScrollView() {// Configures and constrains the scrollView below the header
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func configureStackView() {// Configures the vertical stackView inside the scrollView
        // Configure the stack
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        // Embed in scrollView
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add Constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func configureFloatingButton() {// Adds the “+” floating button in the bottom‐right corner
        let fab = FloatingActionButton()
        view.addSubview(fab)
        
        NSLayoutConstraint.activate([
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        fab.addTarget(self, action: #selector(didTapBudgetAssistant), for: .touchUpInside)
    }
    
    // MARK: – Skeleton & Placeholder
    private func showSkeletonCards() {// Show loading animation while fetching data
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for _ in 0..<3 {
            let skeleton = ShimmerView()
            skeleton.translatesAutoresizingMaskIntoConstraints = false
            skeleton.heightAnchor.constraint(equalToConstant: 140).isActive = true
            stackView.addArrangedSubview(skeleton)
        }
    }
    
    
    private func makeConnectButton() -> UIButton {// Builds “Connect Your Bank” button
        let btn = UIButton(type: .system)
        btn.setTitle("Connect Your Bank", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .secondarySystemBackground// background color
        btn.layer.cornerRadius = 10// Rounded corners and border
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.systemBlue.cgColor
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        btn.widthAnchor.constraint(equalToConstant: 200).isActive = true// button’s width so it doesn’t stretch full width
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true// button’s height
        
        return btn
    }
    
    // MARK: – Data Loading
    
    /// Check Firestore for saved access token
    /// If found, save locally and load summaries
    /// Otherwise show a “Connect Bank” placeholder.
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
    
    /// Remove “Connect Bank” button, fetch from backend, then render cards
    private func loadSummaries() {
        placeholderButton?.removeFromSuperview()
        placeholderButton = nil
        stackView.alignment = .fill
        
        // Call the new, simple, and secure DataService function.
        DataService.loadSummaries { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            self.needsRefresh = false
            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            switch result {
            case .success(let summaries):
                self.summaries = summaries
                self.populateCards()
                self.storeSummariesForWidget(summaries)
                HapticsManager.trigger(.medium)
            case .failure(let error):
                print("❌ Failed to load summaries:", error)
                // Optionally show an error message to the user
            }
        }
    }
    
    private func showPlaceholder(message: String) {
        isLoading = false
        needsRefresh = false
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        placeholderButton?.removeFromSuperview()
        
        let button = makeConnectButton()
        button.setTitle(message, for: .normal) // More flexible placeholder
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
        summaries.forEach { model in//iterate through each item in summaries
            let card = AccountCardView()//create instance of custom card view
            card.configure(with: model)//passes data model to the card
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 140).isActive = true
            //    Add tap gesture to the card
            card.addTarget(self, action: #selector(cardTapped(_:)), for: .touchUpInside)//add tap gesture
            
            stackView.addArrangedSubview(card)//add the card to the stackView
        }
        //        let card = WalletCardView()
        //        card.translatesAutoresizingMaskIntoConstraints = false
        //        card.configure(
        //          bankName:      "Bank of America",
        //          cardholder:    "Noor Singh",
        //          maskedNumber:  "•••• 1234",
        //          expiry:        "08/27",
        //          balance:       2_345.67,
        //          gradientColors:[
        //            UIColor(red: 0.05, green: 0.45, blue: 0.85, alpha: 1),
        //            UIColor(red: 0.15, green: 0.65, blue: 0.95, alpha: 1)
        //          ]
        //        )
        //        stackView.addArrangedSubview(card)
        //
        //        // if in a vertical UIStackView, constrain height:
        //        NSLayoutConstraint.activate([
        //          card.heightAnchor.constraint(equalToConstant: 200)
        //        ])
        
    }
    
    // MARK: – Actions
    /// The action for the main floating button.
    @objc private func didTapBudgetAssistant() {
        let vc = BudgetAssistantViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// The new, correct action for the "Connect Bank" placeholder button.
    @objc private func startPlaidLinkFlow() {
        PlaidService.shared.startPlaidLink(from: self) { [weak self] in
            // On success, we just need to refresh the view.
            self?.needsRefresh = true
            self?.fetchData()
        } onError: { error in
            print("❌ Plaid Link flow failed: \(error)")
            // Optionally show an alert to the user
        }
    }
    
    @objc private func cardTapped(_ card: AccountCardView) {
        guard//unwrap these 3 items below
            let model = card.model
        else { return }
        
        HapticsManager.trigger(.light)
        
        let detailVC = AccountDetailViewController()
        detailVC.period = {
            if model.periodTitle.contains("Today")  { return "today" }
            if model.periodTitle.contains("Week")   { return "week"  }
            if model.periodTitle.contains("Month")  { return "month" }
            return "today"
        }()
        
        navigationController?.pushViewController(detailVC, animated: true)//pushes into navigation stack
    }
    
    @objc private func openProfile() {
        HapticsManager.trigger(.selection)
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    // MARK: – Widget Sync
    private func storeSummariesForWidget(_ summaries: [AccountSummary]) {// Encode summaries and save to App Group for widget
        let entries = summaries.map {
            SummaryEntry(title: $0.periodTitle,
                         amount: $0.amount,
                         subtitle: $0.subtitle)
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults(suiteName: "group.com.your.bundle")?.set(data, forKey: "summaryData")
        }
    }
}

//User taps FAB → fabTapped()
//App sends a POST request to /create_link_token on your Flask backend
//Flask responds with a link_token → used to launch Plaid Link UI
//User completes bank connection → get public_token
//POST public_token to your Flask /exchange_public_token
//Receive access_token → use it to fetch real data (accounts, transactions)
