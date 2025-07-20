//
//  LinkedAccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class LinkedAccountsViewController: UIViewController {
    
    // MARK: – Properties
    
    private var isAccountLinked: Bool = false {
        didSet {
            // This is the single source of truth for our UI state.
            updateUIForLinkStatus()
        }
    }
    
    // Firestore listener registration
    private var firestoreListener: ListenerRegistration?
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCell")
        return tv
    }()
    
    private let emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: – Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Linked Accounts"
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
        setupEmptyStateView()
        addSnapshotListenerForLinkStatus()
    }
    
    deinit {
        // IMPORTANT: Always remove the listener when the view controller is deallocated.
        firestoreListener?.remove()
    }
    
    // MARK: – UI Setup
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupEmptyStateView() {
        view.addSubview(emptyStateView)
        emptyStateView.addTarget(self, action: #selector(addOrReplaceAccount), for: .touchUpInside)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    /// Updates the visibility of UI elements based on whether an account is linked.
    private func updateUIForLinkStatus() {
        // Determine which view to show and which to hide
        let viewToShow = isAccountLinked ? tableView : emptyStateView
        let viewToHide = isAccountLinked ? emptyStateView : tableView
        
        // Animate the transition
        UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            viewToShow.isHidden = false
            viewToHide.isHidden = true
        })
        
        // Reload data if the table is now visible
        if isAccountLinked {
            tableView.reloadData()
        }
    }
    
    // MARK: – Data (Real-time Listener)
    
    /// Attaches a real-time listener to the user's document in Firestore.
    private func addSnapshotListenerForLinkStatus() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.isAccountLinked = false
            return
        }
        
        let docRef = Firestore.firestore().collection("users").document(uid)
        
        // This listener will be called immediately with the current data,
        // and then again every time the data changes on the server.
        firestoreListener = docRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening to document changes: \(error)")
                self.isAccountLinked = false
                return
            }
            
            if let document = document, document.exists {
                self.isAccountLinked = document.data()?["isBankConnected"] as? Bool ?? false
            } else {
                self.isAccountLinked = false
            }
        }
    }
    
    // MARK: – Actions
    
    private func unlinkAccount() {
        PlaidService.shared.unlinkAccount { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // We no longer need to manually update the UI here.
                    // The Firestore listener will detect the change and do it for us.
                    print("Unlink successful. Firestore listener will update UI.")
                    self?.notifyHomeToRefresh()
                case .failure(let error):
                    print("Failed to unlink Plaid item: \(error)")
                    // Show an alert to the user
                }
            }
        }
    }
    
    @objc private func addOrReplaceAccount() {
        startPlaidLinkFlow()
    }
    
    private func startPlaidLinkFlow() {
        PlaidService.shared.startPlaidLink(from: self, onSuccess: { [weak self] in
            // Again, no need to manually set isAccountLinked. The listener handles it.
            print("Plaid Link successful. Firestore listener will update UI.")
            self?.notifyHomeToRefresh()
        }, onError: { error in
            print("Plaid Link flow failed: \(error)")
        })
    }
    
    // MARK: – Coordination
    
    private func notifyHomeToRefresh() {
        // This is still a good idea to have, in case the user navigates back quickly.
        if let nav = navigationController,
           let homeVC = nav.viewControllers.first(where: { $0 is AccountsViewController }) as? AccountsViewController {
            homeVC.needsRefresh = true
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension LinkedAccountsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // The table is only visible when isAccountLinked is true, so we can always return 1.
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
        cell.textLabel?.text = "Bank Account"
        cell.accessoryType = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        unlinkAccount()
    }
}




