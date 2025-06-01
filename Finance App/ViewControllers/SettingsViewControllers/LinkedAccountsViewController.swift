//
//  LinkedAccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//

import UIKit

class LinkedAccountsViewController: UITableViewController {
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "plaidAccessToken") }
        set {
            UserDefaults.standard.set(newValue, forKey: "plaidAccessToken")
            loadAccounts()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Linked Accounts"
        navigationItem.rightBarButtonItem =
        UIBarButtonItem(barButtonSystemItem: .add,
                        target: self,
                        action: #selector(addAccount))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        loadAccounts()
    }
    
    private func loadAccounts() {
        // For now we only store one token; if you support multiple, load them here
        tableView.reloadData()
    }
    
    // MARK: - Table DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tb: UITableView, numberOfRowsInSection sec: Int) -> Int {
        return accessToken == nil ? 0 : 1
    }
    
    override func tableView(_ tb: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tb.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = "My Bank Account"
        cell.detailTextLabel?.text = accessToken
        cell.accessoryType = .detailButton  // “Replace” button
        return cell
    }
    
    // MARK: - Delete (unlink)
    
    override func tableView(_ tb: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt ip: IndexPath) {
        guard editingStyle == .delete, let token = accessToken else { return }
        
        PlaidService.shared.removeItem(accessToken: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // clears UserDefaults for you, then:
                    self?.accessToken = nil
                case .failure(let error):
                    print("Failed to unlink:", error)
                }
            }
        }
    }


    // MARK: - Replace (detail accessory)

    override func tableView(_ tb: UITableView, accessoryButtonTappedForRowWith ip: IndexPath) {
        // Treat “Replace” the same as delete → add
        deleteThenAdd()
    }

    // MARK: - Add / Replace

    @objc private func addAccount() {
        // exactly your fabTapped → create_link_token flow
        PlaidService.shared.startPlaidLink(
                    from: self,
                    onSuccess: { [weak self] in
                        // new token stored in UserDefaults for you
                        self?.loadAccounts()
                    },
                    onError: { error in
                        print("Plaid flow failed:", error)
                        // you could show an alert here
                    }
                )
            }
    

    private func deleteThenAdd() {
        if accessToken != nil {
            // delete first, then open Link
            tableView(self.tableView, commit: .delete, forRowAt: [0,0])
            // give a slight delay to ensure deletion propagates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.addAccount()
            }
        } else {
            addAccount()
        }
    }
}

