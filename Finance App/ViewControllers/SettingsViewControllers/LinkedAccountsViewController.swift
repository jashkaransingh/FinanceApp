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

    /// The single stored Plaid access token (nil if none linked).
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "plaidAccessToken") }
        set {
            UserDefaults.standard.set(newValue, forKey: "plaidAccessToken")
            reloadData()
        }
    }

    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Linked Accounts"
        configureNavigationBar()
        configureTableView()
        reloadData()
    }

    // MARK: – UI Setup

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addAccount)
        )
    }

    private func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "AccountCell"
        )
    }

    // MARK: – Data

    /// Reloads the table view to reflect current `accessToken`.
    private func reloadData() {
        tableView.reloadData()
    }

    // MARK: – Table DataSource

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessToken == nil ? 0 : 1
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AccountCell",
            for: indexPath
        )
        cell.textLabel?.text = "My Bank Account"
        cell.detailTextLabel?.text = accessToken
        cell.accessoryType = .detailButton // Tapping allows “Replace”
        return cell
    }

    // MARK: – Table Editing (Unlink)

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete, let token = accessToken else { return }
        unlinkAccount(token)
    }

    private func unlinkAccount(_ token: String) {
        PlaidService.shared.removeItem(accessToken: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.accessToken = nil
                    self?.notifyHomeToRefresh()
                case .failure(let error):
                    print("❌ Failed to unlink Plaid:", error)
                }
            }
        }
    }

    // MARK: – Accessory Button (Replace)

    override func tableView(
        _ tableView: UITableView,
        accessoryButtonTappedForRowWith indexPath: IndexPath
    ) {
        replaceAccount()
    }

    // MARK: – Add / Replace Account

    @objc private func addAccount() {
        PlaidService.shared.startPlaidLink(
            from: self,
            onSuccess: { [weak self] in
                self?.reloadData()
            },
            onError: { error in
                print("❌ Plaid flow failed:", error)
            }
        )
    }

    private func replaceAccount() {
        if accessToken != nil {
            // Delete first, then add new link after short delay
            unlinkAccount(accessToken!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.addAccount()
            }
        } else {
            addAccount()
        }
    }

    // MARK: – Coordination

    /// Tells the Home (AccountsViewController) to refresh on next appear.
    private func notifyHomeToRefresh() {
        let nav = navigationController
        let homeVC = nav?
            .viewControllers
            .compactMap { $0 as? AccountsViewController }
            .first

        homeVC?.needsRefresh = true
    }
}


