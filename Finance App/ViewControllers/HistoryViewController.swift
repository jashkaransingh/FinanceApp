//
//  HistoryViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HistoryViewController: UIViewController {
    
    // MARK: – UI Components
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var placeholderLabel: UILabel?
    
    // MARK: – Data Storage
    private var allTransactions: [Transaction] = []
    private var transactionsByMonth: [Date: [Transaction]] = [:]
    private var sortedMonthKeys: [Date] = []
    private var monthTotals: [Date: Double] = [:]
    private var isLoading = false
    private let refreshControl = UIRefreshControl()
    
    // MARK: – Formatters
    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    private let monthHeaderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy" // e.g. "June 2025"
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
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.addSubview(refreshControl) // Use addSubview for a non-UITableViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if allTransactions.isEmpty {
            showLoadingState()
            fetchData()
        }
    }
    
    // MARK: – Configuration
    private func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
    
    private func configureTableView() {
        tableView.register(ModernTransactionCell.self, forCellReuseIdentifier: ModernTransactionCell.reuseID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SkeletonCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.contentInsetAdjustmentBehavior = .never
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
    
    @objc private func refreshData() {
        showLoadingState()
        fetchData()
    }
    
    private func fetchData() {
        placeholderLabel?.removeFromSuperview() // Clear any old placeholder
        
        guard let uid = Auth.auth().currentUser?.uid else {
            showPlaceholder(message: "Please sign in to view history.")
            return
        }
        
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists else {
                self?.showPlaceholder(message: "An error occurred.")
                return
            }
            
            let isBankConnected = document.data()?["isBankConnected"] as? Bool ?? false
            if isBankConnected {
                self.fetchLastYearTransactions()
            } else {
                self.showPlaceholder(message: "Connect your bank to see history.")
            }
        }
    }
    
    private func fetchLastYearTransactions() {
        let today = Date()
        guard let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: today) else {
            return
        }
        
        let endDateString = Self.isoDateFormatter.string(from: today)
        let startDateString = Self.isoDateFormatter.string(from: oneYearAgo)
        
        DataService.loadTransactions(startDate: startDateString, endDate: endDateString) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            self.refreshControl.endRefreshing()
            
            switch result {
            case .success(let transactions):
                self.allTransactions = transactions
                self.groupTransactionsByMonth()
                if transactions.isEmpty {
                    self.showPlaceholder(message: "No transactions found for the last year.")
                }
            case .failure(let error):
                print("❌ Failed to fetch transactions:", error)
                self.allTransactions = []
                self.groupTransactionsByMonth()
                self.showPlaceholder(message: "Could not load transactions.")
            }
            
            // Now reload the table with either the real data or the empty state.
            self.tableView.reloadData()
        }
    }
    
    private func groupTransactionsByMonth() {
        // ... (This function remains identical to your original, no changes needed)
        transactionsByMonth.removeAll()
        monthTotals.removeAll()
        sortedMonthKeys.removeAll()
        
        for tx in allTransactions {
            guard let fullDate = HistoryViewController.isoDateFormatter.date(from: tx.date) else { continue }
            let comps = Calendar.current.dateComponents([.year, .month], from: fullDate)
            guard let monthStart = Calendar.current.date(from: comps) else { continue }
            
            transactionsByMonth[monthStart, default: []].append(tx)
        }
        
        for (monthStart, arr) in transactionsByMonth {
            let sortedArr = arr.sorted {
                guard let d1 = HistoryViewController.isoDateFormatter.date(from: $0.date),
                      let d2 = HistoryViewController.isoDateFormatter.date(from: $1.date) else { return false }
                return d1 > d2
            }
            transactionsByMonth[monthStart] = sortedArr
            monthTotals[monthStart] = sortedArr.reduce(0.0) { $0 + $1.amount }
        }
        
        sortedMonthKeys = transactionsByMonth.keys.sorted { $0 > $1 }
    }
    
    // MARK: – State Management
    
    /// Puts the UI into a loading state, showing shimmer cells.
    private func showLoadingState() {
        isLoading = true
        placeholderLabel?.removeFromSuperview()
        // Clear old data before showing loading cells
        allTransactions.removeAll()
        transactionsByMonth.removeAll()
        sortedMonthKeys.removeAll()
        tableView.reloadData()
    }
    
    private func showPlaceholder(message: String) {
        // Clear existing state
        self.isLoading = false
        self.allTransactions = []
        self.groupTransactionsByMonth()
        self.tableView.reloadData()
        
        placeholderLabel?.removeFromSuperview() // Remove old one if it exists
        
        let lbl = UILabel()
        lbl.text = message
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

// MARK: – UITableViewDataSource & Delegate
// The extensions for UITableViewDataSource and UITableViewDelegate remain
// almost identical to your original. The only change is using `isLoading`
// instead of `isLoadingTransactions`. No other changes are needed here.
extension HistoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return isLoading ? 1 : sortedMonthKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 5 // show 5 skeleton rows
        }
        let monthStart = sortedMonthKeys[section]
        let countForMonth = transactionsByMonth[monthStart]?.count ?? 0
        return countForMonth > 0 ? countForMonth + 1 : 0 // +1 for total row, or 0 if no txs
    }
    
    // ... (Your cellForRowAt function can remain the same, just rename the loading flag)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            // ... (shimmer cell logic is unchanged)
            let cell = tableView.dequeueReusableCell(withIdentifier: "SkeletonCell", for: indexPath)
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
            cell.selectionStyle = .none
            return cell
        }
        
        // ... (the rest of your cellForRowAt logic is also unchanged)
        let monthStart = sortedMonthKeys[indexPath.section]
        guard let monthArray = transactionsByMonth[monthStart] else {
            fatalError("No transactions for section \(indexPath.section)")
        }
        
        if indexPath.row == monthArray.count {
            let cellID = "TotalCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: cellID) ?? UITableViewCell(style: .value1, reuseIdentifier: cellID)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
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
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ModernTransactionCell.reuseID, for: indexPath) as? ModernTransactionCell else {
            fatalError("Unable to dequeue ModernTransactionCell")
        }
        let tx = monthArray[indexPath.row]
        cell.configure(with: tx)
        return cell
    }
}

extension HistoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isLoading else { return }
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.4, delay: 0.05 * Double(indexPath.row), options: [.curveEaseOut], animations: {
            cell.alpha = 1
            cell.transform = .identity
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !isLoading else { return nil }
        let monthStart = sortedMonthKeys[section]
        let header = MonthHeaderView()
        header.configure(with: monthStart, formatter: monthHeaderFormatter)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isLoading {
            return 60 // A fixed height for shimmer cells.
        }
        // Let real cells use automatic height.
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isLoading ? 0 : 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}




