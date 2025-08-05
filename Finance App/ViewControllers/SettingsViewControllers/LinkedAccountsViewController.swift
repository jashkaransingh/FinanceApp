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
    private var isAccountLinked: Bool = false
    
    // MARK: - UI Components
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
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
        setupActivityIndicator()
        
        tableView.isHidden = true
        emptyStateView.isHidden = true
        activityIndicator.hidesWhenStopped = true
        emptyStateView.configure(message: "No bank account linked.", buttonTitle: "Link First Account")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchLinkStatus()
    }
    
    // MARK: – UI Setup
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupEmptyStateView() {
        view.addSubview(emptyStateView)
        emptyStateView.setAction(self, action: #selector(addOrReplaceAccount), for: .touchUpInside)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func updateUI() {
        activityIndicator.stopAnimating()
        tableView.isHidden = !isAccountLinked
        emptyStateView.isHidden = isAccountLinked
        
        if isAccountLinked {
            tableView.reloadData()
        }
    }
    
    // MARK: – Data
    
    private func fetchLinkStatus() {
        // Show loading spinner immediately
        tableView.isHidden = true
        emptyStateView.isHidden = true
        activityIndicator.startAnimating()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.isAccountLinked = false
            self.updateUI()
            return
        }
        
        // Perform a quick, one-time fetch
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] doc, error in
            guard let self = self else { return }
            if let error = error {
                // stop spinner & show error
                self.activityIndicator.stopAnimating()
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            if let data = doc?.data(), doc!.exists {
                self.isAccountLinked = data["isBankConnected"] as? Bool ?? false
            } else {
                self.isAccountLinked = false
            }
            self.updateUI()
        }
    }
    
    // MARK: – Actions
    
    private func unlinkAccount() {
        // 1️⃣ Flip the UI immediately so the “Link First Account” button appears
        isAccountLinked = false
        updateUI()

        // 2️⃣ Call unlink without showing the spinner
        PlaidService.shared.unlinkAccount { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    NotificationCenter.default.post(name: .bankAccountUnlinked, object: nil)
                    // UI is already in empty-state; no further work needed
                    
                case .failure(let error):
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(.init(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    
    @objc private func addOrReplaceAccount() {
        startPlaidLinkFlow()
    }
    
    private func startPlaidLinkFlow() {
        PlaidService.shared.startPlaidLink(from: self,
                                           onSuccess: { [weak self] _ in
            guard let self = self else { return }
            NotificationCenter.default.post(name: .bankAccountLinked, object: nil)
            self.fetchLinkStatus()
        },
                                           onError: { [weak self] error in
            guard let self = self else { return }
            print("Plaid Link flow failed: \(error)")
            // you might want to show an alert here too
        })
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension LinkedAccountsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        
        let alert = UIAlertController(title: "Unlink Account?",
                                      message: "Are you sure you want to remove this account? All related data will be deleted.",
                                      preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.unlinkAccount()
        }
        alert.addAction(removeAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}




