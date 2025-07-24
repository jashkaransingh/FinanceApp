//
//  AccountDetailViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class AccountDetailViewController: UIViewController {
    // MARK: – Public API
    var period: String?        // “today” / “week” / “month”
    
    // MARK: – Private Properties
    private let tableView = UITableView()
    private var transactions: [Transaction] = []
    private var isLoading = true
    private var hasAnimatedInitialCells = false
    
    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale     = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        configureTableView()
        loadTransactions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset the flag so you get one entrance animation each time
        hasAnimatedInitialCells = false
    }
    
    private func configureNavigationBar() {
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        title = "\((period ?? "This").capitalized)'s Spending"
    }
    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .automatic
        
        tableView.dataSource = self
        tableView.delegate   = self
        
        tableView.register(
            ModernTransactionCell.self,
            forCellReuseIdentifier: ModernTransactionCell.reuseID
        )
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "SkeletonCell"
        )
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: – Data Loading
    
    /// Computes date range, fetches transactions, and reloads the table.
    private func loadTransactions() {
        guard let per = period, let uid = Auth.auth().currentUser?.uid else {
            // Handle case where period is not set, maybe show an error
            print("Error: AccountDetailViewController requires a period to be set.")
            return
        }
        
        isLoading = true
        tableView.reloadData()
        
        let (start, end) = dateRange(for: per)
        
        let query = Firestore.firestore()
                .collection("users").document(uid).collection("transactions")
                .whereField("date", isGreaterThanOrEqualTo: start.iso8601Format())
                .whereField("date", isLessThanOrEqualTo: end.iso8601Format())
                .order(by: "date", descending: true)

            query.getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isLoading = false
                    if let snapshot = snapshot, error == nil {
                        self.transactions = snapshot.documents.compactMap { try? $0.data(as: Transaction.self) }
                    } else {
                        print("❌ Failed to load detail transactions from Firestore:", error ?? "Unknown error")
                        self.transactions = []
                    }
                    self.tableView.reloadData()
                }
            }
    }
    
    /// Returns start and end `Date` for the given period.
    private func dateRange(for period: String) -> (Date, Date) {
        let today = Date()
        let cal   = Calendar.current
        
        switch period.lowercased() {
        case "today":
            return (today, today)
        case "week":
            let weekAgo = cal.date(byAdding: .day, value: -7, to: today)!
            return (weekAgo, today)
        case "month":
            let monthAgo = cal.date(byAdding: .month, value: -1, to: today)!
            return (monthAgo, today)
        default:
            return (today, today)
        }
    }
}


// MARK: – UITableViewDataSource

extension AccountDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isLoading ? 5 : transactions.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        if isLoading {
            return makeSkeletonCell(for: tableView, at: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ModernTransactionCell.reuseID,
            for: indexPath
        ) as! ModernTransactionCell
        cell.configure(with: transactions[indexPath.row])
        return cell
    }
    
    /// Creates a shimmer “loading” cell.
    private func makeSkeletonCell(
        for tableView: UITableView,
        at indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SkeletonCell",
            for: indexPath
        )
        cell.selectionStyle = .none
        
        // Remove old shimmer views
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let shimmer = ShimmerView()
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(shimmer)
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            shimmer.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            shimmer.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            shimmer.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])
        return cell
    }
}

// MARK: – UITableViewDelegate

extension AccountDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isLoading {
            return 60 // Provide a fixed height for the skeleton cells
        }
        // Let the real cells determine their own height if they have proper constraints
        return UITableView.automaticDimension
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        // Fade-in animation
        guard !isLoading else { return }            // keep your loading guard
        guard !hasAnimatedInitialCells else {        // skip animation after first run
            cell.alpha = 1
            cell.transform = .identity
            return
        }
        
        // Do the fade‑in
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(
            withDuration: 0.4,
            delay: 0.05 * Double(indexPath.row),
            options: [.curveEaseOut]
        ) {
            cell.alpha = 1
            cell.transform = .identity
        } completion: { _ in
            // When the last visible row is done, flip the flag
            if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                self.hasAnimatedInitialCells = true
            }
        }
    }
}
extension Date {
    func iso8601Format() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }
}



