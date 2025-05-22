//
//  AccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import LinkKit


class AccountsViewController: UIViewController {
    private var plaidLinkHandler: Handler?

  private let scrollView = UIScrollView() // declared scroll view
  private let stackView = UIStackView() // declared stackView
  private var summaries: [AccountSummary] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = "My Accounts"

    summaries = DataService.loadSummaries() //Dataservice - place holder values for now
    setupScrollStack()
    populateCards()
    setupFloatingButton()
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

  private func populateCards() {// add the temp placeholder inside the cards
    summaries.forEach { model in
      let card = AccountCardView()
      card.configure(with: model)
      card.translatesAutoresizingMaskIntoConstraints = false
      card.heightAnchor.constraint(equalToConstant: 140).isActive = true
//    Add tap gesture to the card
      let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
      card.addGestureRecognizer(tap)

      stackView.addArrangedSubview(card)//add the card to the stackView
    }
  }

  @objc private func cardTapped(_ recognizer: UITapGestureRecognizer) {
    let detailVC = AccountDetailViewController()
    // you can pass data: detailVC.model = …
    navigationController?.pushViewController(detailVC, animated: true)
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
      guard let url = URL(string: "http://192.168.0.87:5050/create_link_token") else { return }//creates url object for backend address
//        create the http request
          var request = URLRequest(url: url)
          request.httpMethod = "POST"//you're sending data to the server
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
          request.httpBody = try? JSONSerialization.data(withJSONObject: [:])// converts empty swift dict into json data

          URLSession.shared.dataTask(with: request) { data, response, error in
              if let error = error {
                  print("Network error:", error)
                  return
              }
              if let http = response as? HTTPURLResponse {//URLResponse to HTTPURLResponse to read .statuscode
                  print("HTTP status:", http.statusCode)// print like 200 = Ok or 500 = server error
              }
              guard let data = data,
                    let body = String(data: data, encoding: .utf8) else {
                  print("No data in response")
                  return
              }
              print("response body:", body)//print the full json - link token

              guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let linkToken = json["link_token"] as? String else {
                  print("JSON parse failed or missing link_token")
                  return
              }

              DispatchQueue.main.async {//main thread
                  print("Got link token, launching Plaid Link")
                  self.openPlaidLink(with: linkToken)
              }
          }.resume()
  }
    private func openPlaidLink(with linkToken: String) {//this func launches the plaid UI using the tokens we got above
        let config = LinkTokenConfiguration(token: linkToken) { linkSuccess in
          let publicToken = linkSuccess.publicToken
          print("Got public_token: \(publicToken)")//when user successfully connects their bank
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
                print("Access token received: \(accessToken)")
                // Save this or trigger a transaction fetch if you want
            } else {
                print("Failed to exchange token:", error ?? "Unknown error")
            }
        }.resume()
    }

}

//User taps FAB → fabTapped()
//Fetch link_token from your Flask /create_link_token
//Launch Plaid Link UI with that token
//User completes bank connection → get public_token
//POST public_token to your Flask /exchange_public_token
//Receive access_token → use it to fetch real data (accounts, transactions)
