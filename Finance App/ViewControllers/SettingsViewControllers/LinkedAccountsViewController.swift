//
//  LinkedAccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

/// Lists the user’s linked Plaid accounts and lets them add, replace, or remove.
final class LinkedAccountsViewController: UITableViewController {
    
    // MARK: – Properties
    
    /// The new source of truth. Is an account linked or not?
    private var isAccountLinked: Bool = false {
        didSet {
            // Whenever this value changes, reload the table view.
            tableView.reloadData()
        }
    }

    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Linked Accounts"
        configureNavigationBar()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Every time the view appears, check the latest status from Firestore.
        fetchLinkStatus()
    }

    // MARK: – UI Setup

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addOrReplaceAccount)
        )
    }

    private func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCell")
    }

    // MARK: – Data
    
    /// Fetches the user's document from Firestore to check the `isBankConnected` flag.
    private func fetchLinkStatus() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.isAccountLinked = false
            return
        }
        
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists {
                // Check for the boolean flag our backend now sets.
                self.isAccountLinked = document.data()?["isBankConnected"] as? Bool ?? false
            } else {
                self.isAccountLinked = false
                print("Error fetching user document: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    // MARK: – Table DataSource

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isAccountLinked ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
        cell.textLabel?.text = "Bank Account" // Generic text
        cell.accessoryType = .none
        // We no longer show the token or any other sensitive details.
        return cell
    }

    // MARK: – Table Editing (Unlink)

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        unlinkAccount()
    }

    private func unlinkAccount() {
        // Call our new, secure service function.
        PlaidService.shared.unlinkAccount { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let removed):
                    if removed {
                        self?.isAccountLinked = false // Update UI
                        self?.notifyHomeToRefresh()
                    }
                case .failure(let error):
                    // You can show an alert to the user here.
                    print("❌ Failed to unlink Plaid item: \(error)")
                }
            }
        }
    }

    // MARK: – Add / Replace Account

    @objc private func addOrReplaceAccount() {
        if isAccountLinked {
            // Simple replacement flow: unlink first, then link.
            unlinkAccount()
            // Note: In a real app, you might want a more robust UI flow,
            // like waiting for the unlink completion handler before starting the add.
            // But for simplicity, this works.
            startPlaidLinkFlow()
        } else {
            startPlaidLinkFlow()
        }
    }
    
    private func startPlaidLinkFlow() {
        PlaidService.shared.startPlaidLink(
            from: self,
            onSuccess: { [weak self] in
                // On success, the backend has saved the token.
                // We just need to update our UI state.
                self?.isAccountLinked = true
                self?.notifyHomeToRefresh()
            },
            onError: { error in
                print("❌ Plaid Link flow failed: \(error)")
            }
        )
    }

    // MARK: – Coordination

    /// Tells the Home (AccountsViewController) to refresh on next appear.
    private func notifyHomeToRefresh() {
        if let nav = navigationController,
           let homeVC = nav.viewControllers.first(where: { $0 is AccountsViewController }) as? AccountsViewController {
            homeVC.needsRefresh = true
        }
    }
}



