//
//  AccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import LinkKit


class AccountsViewController: UIViewController {
    // MARK: - Properties
    private let headerView = TitleHeaderView()
    private let scrollView = UIScrollView()// declared scroll view
    private let stackView  = UIStackView()// declared stackView
    private var summaries: [AccountSummary] = []
    
    private var plaidLinkHandler: Handler?//retains the plaid handler after the launch
    private var accessToken: String? {//store accessToken to access throught the app
        get { UserDefaults.standard.string(forKey: "plaidAccessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "plaidAccessToken") }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        // Hide the stock nav bar so custom header can sit under the status bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        configureHeader()
        configureScrollView()
        setupScrollStack()
        setupFloatingButton()
        loadSummaries()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore the nav bar for downstream VCs
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    // MARK: - Layout Helpers
    
    private func configureHeader() {
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
    
    private func configureScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupScrollStack() {
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
    
    private func loadSummaries() {//to fetch user's summary data from your backend
        guard let token = accessToken else { return }
        DataService.loadSummariesFromBackend(accessToken: token) { fetched in//call method to fetch summary from backend
            self.summaries = fetched//stores the summary
            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }//remove existing cards from the stackView to prevent duplication
            self.populateCards()//add new accountCardView instance using fresh data
        }
    }
    
    private func setupFloatingButton() {
        let fab = FloatingActionButton()
        view.addSubview(fab)
        NSLayoutConstraint.activate([
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        fab.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
    }
    
    //Add comment here
    @objc private func fabTapped() {
        PlaidService.shared.startPlaidLink(
            from: self,
            onSuccess: { [weak self] in
                // once linked, reload their summary cards
                self?.loadSummaries()
            },
            onError: { error in
                print("Plaid flow failed:", error)
                // show an alert if you like
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
