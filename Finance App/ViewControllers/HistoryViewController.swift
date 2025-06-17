//
//  HistoryViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class HistoryViewController: UIViewController {
    
    // MARK: – UI Components
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var placeholderLabel: UILabel?
    
    // MARK: – Data Storage
    private var allTransactions: [Transaction] = []
    private var transactionsByMonth: [Date: [Transaction]] = [:]
    private var sortedMonthKeys: [Date] = []
    private var monthTotals: [Date: Double] = [:]
    private var isLoadingTransactions = false
    
    // MARK: – Formatters
    private static let isoDateFormatter: DateFormatter = {// Parses `"yyyy-MM-dd"` dates from the backend
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    private let monthHeaderFormatter: DateFormatter = {// Formats section headers as “June 2025”, etc.
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy" // “June 2025”
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    // MARK: – Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = "History"
        
        configureNavigationBar()
        configureTableView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        placeholderLabel?.removeFromSuperview()//Remove old placeholder if any
        
        guard let token = UserDefaults.standard.string(forKey: "plaidAccessToken"),//If no token, show label & return
              !token.isEmpty
        else {
            isLoadingTransactions = false
            tableView.reloadData()
            showConnectBankPlaceholderInHistory()
            return
        }
        //Token exists → fetch
        isLoadingTransactions = true
        tableView.reloadData()
        fetchLastYearTransactions()
    }
    
    // MARK: – Configuration
    private func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
    }
    
    private func configureTableView() {
        tableView.register(
            ModernTransactionCell.self,
            forCellReuseIdentifier: ModernTransactionCell.reuseID
        )
        tableView.dataSource = self
        tableView.delegate   = self
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle  = .none
        tableView.showsVerticalScrollIndicator = false
        
        // iOS 15+: remove the extra top padding above section headers
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        // Let iOS automatically inset the content so it sits below the large title
        tableView.contentInsetAdjustmentBehavior = .never
        
        // Bottom inset so the final “Monthly Total” row isn’t flush against a tab bar
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
    }
    
    // MARK: – Data Fetch
    
    private func fetchLastYearTransactions() {
        guard let token = PlaidService.shared.currentAccessToken else {//Loads transactions for the past given number of years
            print(" No valid access token.")
            return
        }
        
        let today = Date()
        let calendar = Calendar.current
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) else {
            return
        }
        let endStr = HistoryViewController.isoDateFormatter.string(from: today)
        let startStr = HistoryViewController.isoDateFormatter.string(from: oneYearAgo)
        
        DataService.loadTransactions(
            accessToken: token,
            startDate: startStr,
            endDate: endStr
        ) { [weak self] txs in
            guard let self = self else { return }
            self.allTransactions = txs
            self.groupTransactionsByMonth()
            // stop loading
            self.isLoadingTransactions = false
            self.tableView.reloadData()
        }
    }
    
    private func groupTransactionsByMonth() {// Groups `allTransactions` by their month and computes totals.
        transactionsByMonth.removeAll()
        monthTotals.removeAll()
        sortedMonthKeys.removeAll()
        
        for tx in allTransactions {
            guard let fullDate = HistoryViewController.isoDateFormatter.date(from: tx.date) else { continue }
            let comps = Calendar.current.dateComponents([.year, .month], from: fullDate)
            guard let monthStart = Calendar.current.date(from: comps) else { continue }
            
            if var arr = transactionsByMonth[monthStart] {
                arr.append(tx)
                transactionsByMonth[monthStart] = arr
            } else {
                transactionsByMonth[monthStart] = [tx]
            }
        }
        
        for (monthStart, arr) in transactionsByMonth {
            // Sort descending by date
            let sortedArr = arr.sorted { lhs, rhs in
                guard
                    let d1 = HistoryViewController.isoDateFormatter.date(from: lhs.date),
                    let d2 = HistoryViewController.isoDateFormatter.date(from: rhs.date)
                else { return false }
                return d1 > d2
            }
            transactionsByMonth[monthStart] = sortedArr
            
            // Compute monthly total
            let total = sortedArr.reduce(0.0) { sum, tx in
                return sum + tx.amount
            }
            monthTotals[monthStart] = total
        }
        
        // Sort month keys (newest first)
        sortedMonthKeys = transactionsByMonth.keys.sorted { $0 > $1 }
    }
    
    // MARK: – Placeholder
    private func showConnectBankPlaceholderInHistory() {
        let lbl = UILabel()
        lbl.text = "Connect your bank to see history"
        lbl.font = .systemFont(ofSize: 18, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        placeholderLabel = lbl
        view.addSubview(lbl)
        
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

// MARK: – UITableViewDataSource

extension HistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return isLoadingTransactions ? 1 : sortedMonthKeys.count
    }
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if isLoadingTransactions {
            return 5 // show 5 skeleton rows
        }
        let monthStart = sortedMonthKeys[section]
        let countForMonth = transactionsByMonth[monthStart]?.count ?? 0
        // +1 for the “Monthly Total” row
        return countForMonth + 1
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        if isLoadingTransactions {
            // dequeue a basic cell, clear its content, and add a shimmer view
            let cellID = "SkeletonCell"
            let cell = tableView.dequeueReusableCell(
                withIdentifier: cellID
            ) ?? UITableViewCell(style: .default, reuseIdentifier: cellID)
            
            // remove old shimmer if any
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            // add one shimmer bar
            let shimmer = ShimmerView()
            shimmer.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(shimmer)
            NSLayoutConstraint.activate([
                shimmer.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                shimmer.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                shimmer.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                shimmer.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            cell.selectionStyle = .none
            return cell
        }
        
        // otherwise, your existing “real” cell logic...
        
        
        let monthStart = sortedMonthKeys[indexPath.section]
        guard let monthArray = transactionsByMonth[monthStart] else {
            fatalError("No transactions for section \(indexPath.section)")
        }
        
        // If this is the last row in the section, show the “Monthly Total”
        if indexPath.row == monthArray.count {
            let cellID = "TotalCell"
            let cell: UITableViewCell
            if let reused = tableView.dequeueReusableCell(withIdentifier: cellID) {
                cell = reused
            } else {
                cell = UITableViewCell(style: .value1, reuseIdentifier: cellID)
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            }
            cell.textLabel?.text = "Monthly Total"
            if let total = monthTotals[monthStart] {
                let fmt = NumberFormatter()
                fmt.numberStyle = .currency
                cell.detailTextLabel?.text = fmt.string(from: NSNumber(value: total))
            } else {
                cell.detailTextLabel?.text = nil
            }
            return cell
        }
        
        // Otherwise, show a normal ModernTransactionCell
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ModernTransactionCell.reuseID,
            for: indexPath
        ) as? ModernTransactionCell else {
            fatalError("Unable to dequeue ModernTransactionCell")
        }
        let tx = monthArray[indexPath.row]
        cell.configure(with: tx)
        return cell
    }
}

// MARK: – UITableViewDelegate

extension HistoryViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        // (Optional) Fade-in animation for each row
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(
            withDuration: 0.4,
            delay: 0.05 * Double(indexPath.row),
            options: [.curveEaseOut],
            animations: {
                cell.alpha = 1
                cell.transform = .identity
            },
            completion: nil
        )
    }
    
    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        guard !isLoadingTransactions else { return nil }
        let monthStart = sortedMonthKeys[section]
        let header = MonthHeaderView()
        header.configure(with: monthStart, formatter: monthHeaderFormatter)
        return header
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 50
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForFooterInSection section: Int
    ) -> CGFloat {
        return 8
    }
    
    func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}




