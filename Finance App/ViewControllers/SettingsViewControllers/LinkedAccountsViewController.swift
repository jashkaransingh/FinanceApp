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
    private var didPerformFirstUIUpdate = false
    private var isAccountLinked: Bool = false {
        didSet {
            updateUIForLinkStatus(animated: didPerformFirstUIUpdate)
            didPerformFirstUIUpdate = true
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
        tableView.isHidden      = true
        emptyStateView.isHidden = true
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(uid)
                .getDocument { [weak self] doc, _ in
                    let linked = doc?.data()?["isBankConnected"] as? Bool ?? false
                    self?.isAccountLinked = linked
                }
        }
        // 2) Then listen for live updates
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
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    /// Updates the visibility of UI elements based on whether an account is linked.
    private func updateUIForLinkStatus(animated: Bool) {
        let show = isAccountLinked ? tableView : emptyStateView
        let hide = isAccountLinked ? emptyStateView : tableView
        
        let changes = {
            show.isHidden = false
            hide.isHidden = true
        }
        
        if animated {
            UIView.transition(
                with: view,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: changes
            )
        } else {
            changes()
        }
        
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
            print("🔥 FIRESTORE LISTENER FIRED! 🔥")
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
        // Show a loading indicator here if you have one
        PlaidService.shared.unlinkAccount { [weak self] result in
            // Hide loading indicator
            guard let self = self else { return }
            
            switch result {
            case .success:
                // 1) Update Firestore (you already do that in your /remove_item endpoint)
                // 2) Notify the home screen to refresh
                NotificationCenter.default.post(name: .bankLinkChanged, object: nil)
                // This part remains the same. The Firestore listener will handle the UI update.
                print("Unlink successful. Firestore listener will update UI.")
                
            case .failure(let error):
                // This is the new, powerful error handling.
                switch error {
                case .sessionExpired:
                    // The user's token is invalid. Force them to log in again.
                    print("Session expired. Forcing user to re-login.")
                    SceneDelegate.switchToLogin() // Use your existing function!
                    
                case .serverError(let message):
                    // A specific error from your server or the network.
                    self.presentAlert(title: "Server Error", message: message)
                    
                default:
                    // A generic error for other cases.
                    self.presentAlert(title: "Error", message: "An unexpected error occurred. Please try again.")
                }
            }
        }
    }
    
    @objc private func addOrReplaceAccount() {
        startPlaidLinkFlow()
    }
    
    private func startPlaidLinkFlow() {
        PlaidService.shared.startPlaidLink(from: self, onSuccess: { [weak self] in
            guard let self = self else { return }
            // 1) Firestore is updated in exchange_public_token
            // 2) Now tell home screen to reload
            NotificationCenter.default.post(name: .bankLinkChanged, object: nil)
            print("Link successful. Refresh posted.")
            
        }, onError: { error in
            print("Plaid Link flow failed: \(error)")
        })
    }
    
    // MARK: – Coordination
    
    //    private func notifyHomeToRefresh() {
    //        // This is still a good idea to have, in case the user navigates back quickly.
    //        if let nav = navigationController,
    //           let homeVC = nav.viewControllers.first(where: { $0 is AccountsViewController }) as? AccountsViewController {
    //            homeVC.needsRefresh = true
    //        }
    //    }
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




