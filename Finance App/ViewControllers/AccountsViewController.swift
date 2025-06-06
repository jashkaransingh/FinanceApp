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
    // MARK: - Properties
    private let headerView = TitleHeaderView()// 'My Accounts' header at top
    private let scrollView = UIScrollView()// Scrollable area for cards
    private let stackView  = UIStackView()// Vertical stack inside scrollView
    private var summaries: [AccountSummary] = []//list of account summaries (fetched from backend)
    var needsRefresh = true// Tracks whether we need to re‐fetch the cards
    private var placeholderButton: UIButton?// If no accounts exist yet, we show a placeholder “Connect Bank” button
    
    
    private var plaidLinkHandler: Handler?//retains the plaid handler after the launch
    private var accessToken: String? {//store accessToken to access throught the app
        get { UserDefaults.standard.string(forKey: "plaidAccessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "plaidAccessToken") }
    }
    
    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        // Hide the stock nav bar so custom header can sit under the status bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        configureHeader()
        configureScrollView()
        setupScrollStack()
        setupFloatingButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // When leaving this screen, restore the nav bar for downstream VCs
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        guard needsRefresh else {
            // No need to re‐fetch; the UI is already up‐to‐date
            return
        }
        // If needsRefresh is true, check Firestore for bank status
        fetchBankStatusFromFirestore()
    }
    
    // MARK: - Layout Helpers
    
    private func configureHeader() {// Configures and constrains the custom headerView.
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,   constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44) // match native nav-bar height
        ])
        
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
    
    private func setupScrollStack() {// Configures the vertical stackView inside the scrollView
        // 1) Configure the stack
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        // 2) Embed in scroll
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3) Pin edges & width
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupFloatingButton() {// Adds the “+” floating button in the bottom‐right corner
        let fab = FloatingActionButton()
        view.addSubview(fab)
        NSLayoutConstraint.activate([
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        fab.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
    }
    
    
    // MARK: – Firestore Check
    
    /// 1 Look up the current user’s Firestore document.
    /// 2 If `bankAccessToken` exists, store it locally & load cards.
    /// 3 Otherwise show a “Connect Bank” placeholder.
    private func fetchBankStatusFromFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // If no logged-in user, default to showing “Connect Bank”
            showConnectBankPlaceholder()
            needsRefresh = false
            return
        }
        
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let token = data["bankAccessToken"] as? String
            {
                // They’ve linked before: save locally & load the real cards
                self.accessToken = token
                self.loadSummariesAndShowCards()
                // 2) Now that UI is drawn, mark needsRefresh = false
                self.needsRefresh = false  // ← HERE
            } else {
                // No token in Firestore → show the “Connect Bank” button
                self.showConnectBankPlaceholder()
                // 2) We just drew the placeholder UI, so mark needsRefresh = false
                self.needsRefresh = false  // ← HERE
            }
        }
    }
    
    /// Called once we know there is a valid bank token. This is just your old `loadSummaries()` + `populateCards()`,
    /// but we also remove any “placeholder” subview first.
    private func loadSummariesAndShowCards() {
        // ② Before you draw cards, make sure to remove the placeholder from `view`:
        placeholderButton?.removeFromSuperview()
        placeholderButton = nil
        // 1) Remove any “Connect Bank” button if it was added earlier
        self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        stackView.alignment = .fill
        
        // 2) Now call the same code you already had in `loadSummaries()`
        guard let token = accessToken else { return }
        DataService.loadSummariesFromBackend(accessToken: token) { fetched in
            self.summaries = fetched
            self.populateCards()
            self.storeSummariesForWidget(fetched)
        }
    }
    private func storeSummariesForWidget(_ summaries: [AccountSummary]) {
        let entries = summaries.map {
            SummaryEntry(title: $0.periodTitle,
                         amount: $0.amount,
                         subtitle: $0.subtitle)
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults(suiteName: "group.com.your.bundle")?.set(data, forKey: "summaryData")
        }
    }

    
    /// If we don’t have a bank token yet, show a single big button in place of the cards.
    private func showConnectBankPlaceholder() {
        // 1) Remove any previous arranged subviews from stack (if you still care about the stack’s old contents)
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // If there’s already a placeholder sitting in `view`, remove it first:
        placeholderButton?.removeFromSuperview()
        
        // Build a new placeholder:
        let button = makeConnectButton()
        button.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        
        // Keep a reference so we can tear it down later:
        placeholderButton = button
        
        // Add it to `view` and center it:
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

    }
    
    /// Builds and returns a “Connect Your Bank” button with borders, corner radius, and custom color.
    private func makeConnectButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("Connect Your Bank", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        
        // Give it a background color that contrasts with the grouped background
        btn.backgroundColor = .secondarySystemBackground
        
        // Rounded corners and border
        btn.layer.cornerRadius = 10
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.systemBlue.cgColor
        
        // Must disable autoresizing-mask translation before applying Auto Layout constraints
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        // Fix the button’s width (so it doesn’t stretch full width)
        btn.widthAnchor.constraint(equalToConstant: 200).isActive = true
        // Fix the height (e.g. 50 points tall)
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return btn
    }
    
    
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
    }
    
    @objc private func openProfile() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    
    @objc private func cardTapped(_ card: AccountCardView) {
        guard//unwrap these 3 items below
            let model = card.model,
            let token = accessToken
        else { return }
        
        let detailVC = AccountDetailViewController()//create the instance of accountViewcontroller to display
        detailVC.accessToken = token//passes the stored accessToken to detailView to authorize fetch transaction request
        // translate your model.periodTitle into the API’s “today”/“week”/“month”
        detailVC.period = {
            if model.periodTitle.contains("Today")  { return "today" }
            if model.periodTitle.contains("Week")   { return "week"  }
            if model.periodTitle.contains("Month")  { return "month" }
            return "today"
        }()
        
        navigationController?.pushViewController(detailVC, animated: true)//pushes into navigation stack
    }
    
    //    private func loadSummaries() {//to fetch user's summary data from your backend
    //        guard let token = accessToken else { return }
    //        DataService.loadSummariesFromBackend(accessToken: token) { fetched in//call method to fetch summary from backend
    //            self.summaries = fetched//stores the summary
    //            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }//remove existing cards from the stackView to prevent duplication
    //            self.populateCards()//add new accountCardView instance using fresh data
    //        }
    //    }
    
    
    //Add comment here
    @objc private func fabTapped() {
        PlaidService.shared.startPlaidLink(
            from: self,
            onSuccess: { [weak self] in
                guard let self = self else { return }
                // We have just written a fresh token into Firestore + UserDefaults
                self.needsRefresh = true   // ← HERE
                
                // Then immediately load summaries and show cards:
                self.loadSummariesAndShowCards()
            },
            onError: { error in
                print("Plaid flow failed:", error)
            }
        )
    }
    
}

//User taps FAB → fabTapped()
//App sends a POST request to /create_link_token on your Flask backend
//Flask responds with a link_token → used to launch Plaid Link UI
//User completes bank connection → get public_token
//POST public_token to your Flask /exchange_public_token
//Receive access_token → use it to fetch real data (accounts, transactions)
