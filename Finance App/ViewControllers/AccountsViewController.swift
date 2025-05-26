//
//  AccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import LinkKit


class AccountsViewController: UIViewController {
    private var plaidLinkHandler: Handler?//retains the plaid handler after the launch
    private var accessToken: String? {//store accessToken to access throught the app
        get { UserDefaults.standard.string(forKey: "plaidAccessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "plaidAccessToken") }
    }
    private let scrollView = UIScrollView()// declared scroll view
    private let stackView  = UIStackView()// declared stackView
    private var summaries: [AccountSummary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "My Accounts"
        
        setupScrollStack()
        setupFloatingButton()
        loadSummaries()
    }
    
    private func setupScrollStack() {
        //  Setting up the scrollView
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        //  Setting up the stackView
        stackView.axis = .vertical
        stackView.spacing = 16 //spacing between the cards inside the stackview
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        scrollView.addSubview(stackView)//add stackview in scrollview
        //  Constraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
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
            let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))//add tap gesture
            card.addGestureRecognizer(tap)
            
            stackView.addArrangedSubview(card)//add the card to the stackView
        }
    }
    
    @objc private func cardTapped(_ recognizer: UITapGestureRecognizer) {
        guard//unwrap these 3 items below
            let card = recognizer.view as? AccountCardView,
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
    @objc private func fabTapped() {//@obj because it's called by a gesture or a button (FloatingActionButton)
        //Build the URL for your backend’s create_link_token route
        guard let url = URL(string: "http://192.168.0.87:5050/create_link_token")
        else { return }
        
        //Create the POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [:])
        
        //Starts an asynchronous network call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error:", error)
                return
            }
            if let http = response as? HTTPURLResponse {
            }
            guard let data = data,
                  let bodyString = String(data: data, encoding: .utf8) else {
                print("No data in response")
                return
            }
            
            //Parse the raw JSON response into a dictionary
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let linkToken = json["link_token"] as? String else {
                print("JSON parse failed or missing link_token")
                return
            }
            
            //Back on the main thread, launch Plaid Link
            DispatchQueue.main.async {
                self.openPlaidLink(with: linkToken)
            }
        }
        .resume()
    }
    private func openPlaidLink(with linkToken: String) {//this func launches the plaid UI using the tokens we got above
        let config = LinkTokenConfiguration(token: linkToken) { linkSuccess in
            let publicToken = linkSuccess.publicToken
            self.sendPublicTokenToBackend(publicToken)//send public token to backend
        }
        
        let result = Plaid.create(config)//plaid sdk return result - success or failure
        
        //handle only the success case and **retain** the handler
        switch result {
        case .success(let handler):
            // store it in your property so it doesn’t go out of scope
            self.plaidLinkHandler = handler
            
            // present on your view controller
            handler.open(presentUsing: .viewController(self))
            
        case .failure(let error):
            print("Plaid Link creation failed:", error)
        }
    }
    
    private func sendPublicTokenToBackend(_ publicToken: String) {//share the public token with backend for long live access on backend
        guard let url = URL(string: "http://192.168.0.87:5050/exchange_public_token") else { return }
        //      same step as fabTapped but now sending public token
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["public_token": publicToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        //      Handle the response from backend
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String {
                self.accessToken = accessToken               // store it
                self.loadSummaries()
                self.fetchTransactions(accessToken: accessToken)
            } else {
                print("Failed to exchange token:", error ?? "Unknown error")
            }
        }.resume()
    }
    
    func refreshTransactions(accessToken: String) {
        guard let url = URL(string: "http://192.168.0.87:5050/refresh") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["access_token": accessToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return
            }
        }.resume()
    }
    
    func fetchTransactions(accessToken: String) {
        guard let url = URL(string: "http://192.168.0.87:5050/transactions?access_token=\(accessToken)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let transactions = json["transactions"] as? [[String: Any]] {
                print("Fetched transactions: \(transactions)")
            } else {
            }
        }.resume()
    }
    
}

//User taps FAB → fabTapped()
//App sends a POST request to /create_link_token on your Flask backend
//Flask responds with a link_token → used to launch Plaid Link UI
//User completes bank authentication → Plaid returns a public_token
//POST public_token to your Flask /exchange_public_token
//Receive access_token → use it to fetch real data (accounts, transactions)
