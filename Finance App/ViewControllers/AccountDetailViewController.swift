//
//  AccountDetailViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class AccountDetailViewController: UIViewController {
    // MARK: – Public API
    var accessToken: String?
    var period: String?        // “today” / “week” / “month”
    
    // MARK: – Private Properties
    private let tableView = UITableView()
    private var transactions: [Transaction] = []
    private var isLoading = true
    
    private let isoDateFormatter: DateFormatter = {
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
    
    private func configureNavigationBar() {
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        guard
            let token = accessToken,
            let per   = period
        else {
            fatalError("AccountDetailViewController: missing accessToken or period")
        }
        title = "\(per.capitalized)’s Spending"
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
        guard
            let token = accessToken,
            let per   = period
        else { return }
        
        isLoading = true
        tableView.reloadData()
        
        let (start, end) = dateRange(for: per)
        let startStr = isoDateFormatter.string(from: start)
        let endStr   = isoDateFormatter.string(from: end)
        
        DataService.loadTransactions(
            accessToken: token,
            startDate:   startStr,
            endDate:     endStr
        ) { [weak self] txs in
            guard let self = self else { return }
            // Brief delay to make shimmer visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transactions = txs
                self.isLoading = false
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
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        // Fade-in animation
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(
            withDuration: 0.4,
            delay: 0.05 * Double(indexPath.row),
            options: [.curveEaseOut],
            animations: {
                cell.alpha = 1
                cell.transform = .identity
            }
        )
    }
}



