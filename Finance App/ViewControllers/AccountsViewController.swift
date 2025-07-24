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
    private let refreshControl = UIRefreshControl()
    
    // MARK: – Data Properties
    private var summaries: [AccountSummary] = []//list of account summaries (fetched from backend)
    private var listener: ListenerRegistration?
    private var placeholderButton: UIButton?// If no accounts exist yet, we show a placeholder “Connect Bank” button
    
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
        // 1) Always hide the stock nav‑bar before laying out your custom header
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // 2) (Re)attach your Firestore listener so you get live updates
        attachListener()
      }

      override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 1) Restore the nav‑bar so downstream VCs get the standard bar
        navigationController?.setNavigationBarHidden(false, animated: animated)

        // 2) Cleanup the listener
        listener?.remove()
        listener = nil

        // 3) If the user was mid‑pull‑to‑refresh, cancel it
        if refreshControl.isRefreshing {
          refreshControl.endRefreshing()
        }
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
        
    }
    
        private func configureScrollView() {// Configures and constrains the scrollView below the header
          view.addSubview(scrollView)
          scrollView.alwaysBounceVertical = true
          scrollView.translatesAutoresizingMaskIntoConstraints = false

          // ← Preferred, since iOS 10:
          if #available(iOS 10.0, *) {
            scrollView.refreshControl = refreshControl
          } else {
            scrollView.addSubview(refreshControl)
          }
          refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)

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
    
    @objc private func refreshData() {
        // We just tell the server to sync transactions.
        // Our listener will automatically pick up any changes to the summaries.
        DataService.loadTransactions(period: "month") { _ in
            // We don't need to do anything in the completion handler.
            self.refreshControl.endRefreshing()
        }
    }
    
    /// Attaches a real-time listener to the user document to get live summary updates.
    // In AccountsViewController.swift

    /// Attaches a real-time listener to the user document to get live summary updates.
    private func attachListener() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showPlaceholder(message: "Please sign in.")
            return
        }
        showSkeletonCards()
        
        let docRef = Firestore.firestore().collection("users").document(uid)
        listener = docRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            self.refreshControl.endRefreshing()
            
            if let error = error {
                print("Firestore listener error: \(error.localizedDescription)")
                self.showPlaceholder(message: "Could not connect.")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("User document does not exist.")
                self.showPlaceholder(message: "An error occurred.")
                return
            }
            
            // This is a much safer way to decode.
            // We first check if the 'accountSummaries' field exists at all.
            guard let userData = document.data(), let _ = userData["accountSummaries"] else {
                self.showPlaceholder(message: "Syncing your accounts...")
                // The backend hasn't generated the summaries yet. We need to ask for them.
                // We use the refreshData function to do this.
                self.refreshData()
                return
            }
            
            // Now that we know the field exists, we can safely decode.
            do {
                self.summaries = try document.data(as: UserData.self).accountSummaries ?? []
                self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                self.placeholderButton?.removeFromSuperview()
                self.populateCards()
                
            } catch {
                print("Error decoding user data from Firestore: \(error)")
                self.showPlaceholder(message: "Could not load accounts.")
            }
        }
    }
    
    private func showPlaceholder(message: String) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        placeholderButton?.removeFromSuperview()
        refreshControl.endRefreshing()
        
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
            guard let self = self else { return }
            let uid = Auth.auth().currentUser!.uid
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData(["isBankConnected": true], merge: true) { error in
                    if let error = error {
                        print("couldn’t mark bank connected:", error)
                        return
                    }
                }
        } onError: { error in
            print("Plaid Link flow failed:", error)
        }
    }
    
    @objc private func cardTapped(_ card: AccountCardView) {
        guard//unwrap model
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
