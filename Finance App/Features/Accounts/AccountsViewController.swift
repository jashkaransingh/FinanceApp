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

@MainActor
final class AccountsViewController: UIViewController {
    
    private enum PlaceholderText {
        static let connect = "Connect Your Bank"
        static let syncing = "Syncing your accounts..."
        static let signedOut = "Please sign in."
        static let cannotConnect = "Could not connect."
        static let genericError = "An error occurred."
    }

    
    // MARK: - UI Properties
    private let headerView = TitleHeaderView()// 'My Accounts' header at top
    private let scrollView = UIScrollView()// Scrollable area for cards
    private let stackView  = UIStackView()// Vertical stack inside scrollView
    private let refreshControl = UIRefreshControl()
    private var tempPlaceholderLabel: UILabel?
    private let aiBadgeContainer: UIView = {
        let view = UIView()
        // Adaptive background: white@60% in light, black@60% in dark
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        view.layer.cornerRadius = 14
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let aiBadgeIcon: UIImageView = {
            let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            // Fallback for iOS < 18 (so lowering your deployment target won’t break)
            let name: String
            if #available(iOS 18.0, *) {
                name = "apple.intelligence"
            } else {
                name = "sparkles" // simple, supported everywhere
            }
            let iv = UIImageView(image: UIImage(systemName: name, withConfiguration: config))
            iv.tintColor = .label
            iv.translatesAutoresizingMaskIntoConstraints = false
            return iv
        }()
    
    private let aiBadgeLabel: UILabel = {
        // Uppercase + letter spacing
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.label,  // dynamic
            .kern: 1.2
        ]
        let lbl = UILabel()
        lbl.attributedText = NSAttributedString(string: "BUDGET AI", attributes: attrs)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleBankAccountUnlinked),
                                               name: .bankAccountUnlinked,
                                               object: nil)
        
    }
    
    deinit {
            NotificationCenter.default.removeObserver(self, name: .bankAccountUnlinked, object: nil)
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
        
        scrollView.keyboardDismissMode = .interactive

                scrollView.refreshControl = refreshControl
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
    
    private func configureFloatingButton() {
            let fab = FloatingActionButton()
            fab.accessibilityLabel = "Open Budget Assistant"
            view.addSubview(fab)
            fab.addTarget(self, action: #selector(didTapBudgetAssistant), for: .touchUpInside)

            view.addSubview(aiBadgeContainer)
            aiBadgeContainer.addSubview(aiBadgeIcon)
            aiBadgeContainer.addSubview(aiBadgeLabel)

            NSLayoutConstraint.activate([
                fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

                aiBadgeContainer.centerYAnchor.constraint(equalTo: fab.centerYAnchor),
                aiBadgeContainer.trailingAnchor.constraint(equalTo: fab.leadingAnchor, constant: -12),
                aiBadgeContainer.heightAnchor.constraint(equalToConstant: 28),

                aiBadgeIcon.leadingAnchor.constraint(equalTo: aiBadgeContainer.leadingAnchor, constant: 8),
                aiBadgeIcon.centerYAnchor.constraint(equalTo: aiBadgeContainer.centerYAnchor),

                aiBadgeLabel.leadingAnchor.constraint(equalTo: aiBadgeIcon.trailingAnchor, constant: 4),
                aiBadgeLabel.trailingAnchor.constraint(equalTo: aiBadgeContainer.trailingAnchor, constant: -8),
                aiBadgeLabel.centerYAnchor.constraint(equalTo: aiBadgeContainer.centerYAnchor)
            ])

            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.duration = 1.8; pulse.fromValue = 1.0; pulse.toValue = 1.03
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulse.autoreverses = true; pulse.repeatCount = .infinity
            aiBadgeContainer.layer.add(pulse, forKey: "pulse")
        }
    
    
    
    // MARK: – Skeleton & Placeholder
    private func showSkeletonCards() {// Show loading animation while fetching data
        placeholderButton?.removeFromSuperview()
        tempPlaceholderLabel?.removeFromSuperview()
        scrollView.isHidden = false
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for _ in 0..<3 {
            let skeleton = ShimmerView()
            skeleton.translatesAutoresizingMaskIntoConstraints = false
            skeleton.heightAnchor.constraint(equalToConstant: 132).isActive = true
            skeleton.startAnimating()
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
    @objc private func handleBankAccountUnlinked() {
        attachListener()
    }
    
    /// Attaches a real-time listener to the user document to get live summary updates.
    // In AccountsViewController.swift
    
    /// Attaches a real-time listener to the user document to get live summary updates.
    private func attachListener() {
        listener?.remove()
            listener = nil
        guard let uid = Auth.auth().currentUser?.uid else {
            showPlaceholder(message: PlaceholderText.signedOut)
            return
        }
        
        showSkeletonCards()
        
        let docRef = Firestore.firestore().collection("users").document(uid)
        listener = docRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
            
            // --- NEW, SMARTER LOGIC STARTS HERE ---
            
            if let error = error {
                print("Firestore listener error: \(error.localizedDescription)")
                self.showPlaceholder(message: PlaceholderText.cannotConnect)
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                self.showPlaceholder(message: PlaceholderText.genericError)
                return
            }
            
            // 1. Decode the entire user document into a model.
            //    We need to create a simple UserData struct for this.
            let userData = try? document.data(as: UserProfile.self)
//            update Header
            if let bank = userData?.bankName, !bank.isEmpty {
              headerView.title = "\(bank) Account"
            } else {
              headerView.title = "My Accounts"
            }
            
            // 2. Check the single source of truth: isBankConnected
            //    (We will add this property to your UserProfile model)
            if userData?.isBankConnected == true {
                // THE BANK IS CONNECTED.
                // Now, check if the summary data is ready.
                if let summaries = userData?.accountSummaries, !summaries.isEmpty {
                    // Data is ready! Show the cards.
                    self.summaries = summaries
                    self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                    self.placeholderButton?.removeFromSuperview()
                    self.populateCards()
                } else {
                    // Bank is linked, but summaries aren't ready yet.
                    // This happens on a new phone or during a slow sync.
                    // Show a specific message and trigger a sync.
                    self.showPlaceholder(message: PlaceholderText.syncing)
                    self.refreshData()
                }
            } else {
                // THE BANK IS NOT CONNECTED.
                // Show the button to connect a bank.
                self.showPlaceholder(message: PlaceholderText.connect)
            }
        }
    }
    
    private func showPlaceholder(message: String) {
        self.scrollView.isHidden = true
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // --- 1. REMOVE BOTH KINDS OF PLACEHOLDERS ---
        placeholderButton?.removeFromSuperview()
        tempPlaceholderLabel?.removeFromSuperview()
        
        refreshControl.endRefreshing()
        
        if message == "Connect Your Bank" {
            let button = makeConnectButton()
            button.setTitle(message, for: .normal)
            button.addTarget(self, action: #selector(startPlaidLinkFlow), for: .touchUpInside)
            placeholderButton = button
            
            view.addSubview(button)
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            ])
        } else {
            let lbl = UILabel()
            lbl.text = message
            lbl.font = .systemFont(ofSize: 18, weight: .medium)
            lbl.textColor = .secondaryLabel
            lbl.textAlignment = .center
            
            tempPlaceholderLabel = lbl // Use the class property
            
            view.addSubview(tempPlaceholderLabel!)
            tempPlaceholderLabel!.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tempPlaceholderLabel!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                tempPlaceholderLabel!.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
        }
    }
    
    
    
    // MARK: – UI Population
    private func populateCards() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        placeholderButton?.removeFromSuperview()
        tempPlaceholderLabel?.removeFromSuperview()
        self.scrollView.isHidden = false
        summaries.forEach { model in//iterate through each item in summaries
            let card = AccountCardView()//create instance of custom card view
            card.configure(with: model)//passes data model to the card
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 132).isActive = true
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
        // 1. Show a loading indicator
        DispatchQueue.main.async {
             UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        // 2. THIS IS THE "SMART" FIX:
        //    First, try to load an *existing* plan.
        DataService.loadBudgetPlan { [weak self] loadResult in
            guard let self = self else { return }

            // This is a helper closure to load transactions.
            // We need transactions for *both* flows (new or existing).
            let transactionLoader: (@escaping ([Transaction]) -> Void) -> Void = { transactionCompletion in
                let endDate = Date()
                guard let startDate = Calendar.current.date(byAdding: .day, value: -42, to: endDate) else {
                    DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
                    return
                }

                let fmt = ISO8601DateFormatter()
                fmt.formatOptions = [.withFullDate]
                let startDateString = fmt.string(from: startDate)
                let endDateString = fmt.string(from: endDate)

                DataService.loadTransactions(startDate: startDateString, endDate: endDateString) { txResult in
                    // Stop the loader *after* transactions are loaded
                    DispatchQueue.main.async {
                         UIApplication.shared.isNetworkActivityIndicatorVisible = false
                         switch txResult {
                         case .success(let transactions):
                             transactionCompletion(transactions) // Send transactions to the next step
                         case .failure(let error):
                            print("❌ Failed to load transactions for Budget AI: \(error)")
                            // TODO: Show a real alert to the user
                         }
                    }
                }
            }

            // 3. Now, handle the result of the loadBudgetPlan call
            switch loadResult {
            case .success:
                // --- FLOW A: PLAN EXISTS ---
                // We have a plan. Load transactions and go *directly* to the assistant.
                print("✅ Found existing budget plan. Loading transactions...")
                transactionLoader { transactions in
                    let vc = BudgetAssistantViewController(
                        transactions: transactions,
                        selectedMerchants: nil // This is the key! This tells the VC to load the saved plan.
                    )
                    self.navigationController?.pushViewController(vc, animated: true)
                }

            case .failure:
                // --- FLOW B: NO PLAN EXISTS (404 Error) ---
                // This is the new user flow. Go to the Habit Selector.
                print("ℹ️ No budget plan found. Starting new user flow...")
                transactionLoader { transactions in
                    let vc = BudgetHabitSelectorViewController(transactions: transactions)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    /// The new, correct action for the "Connect Bank" placeholder button.
    @objc private func startPlaidLinkFlow() {
      PlaidService.shared.startPlaidLink(
        from: self,
        onSuccess: { [weak self] _ in
          // Simply re-fetch the user doc to pick up isBankConnected + bankName
          self?.attachListener()
        },
        onError: { error in
          print("Plaid Link flow failed:", error)
        }
      )
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
        let settingsVC = SettingsViewController()
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
