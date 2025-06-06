//
//  HistoryViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class HistoryViewController: UIViewController {
    // MARK: – Properties
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var allTransactions: [Transaction] = []
    private var transactionsByMonth: [Date: [Transaction]] = [:]
    private var sortedMonthKeys: [Date] = []
    private var monthTotals: [Date: Double] = [:]  // holds each month’s total sum

    /// DateFormatter for parsing “YYYY-MM-DD” strings from the backend
    private let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// DateFormatter for section headers, e.g. “June 2025”
    private let monthHeaderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "History"
        
        configureTableView()
        fetchLastYearTransactions()
    }

    // MARK: – Table Setup

    private func configureTableView() {
        tableView.register(
            TransactionCellView.self,
            forCellReuseIdentifier: TransactionCellView.reuseID
        )
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: – Data Fetch

    /// Fetches transactions from one year ago until today, then groups and reloads.
    private func fetchLastYearTransactions() {
        // 1) Get stored access token
        guard let token = UserDefaults.standard.string(forKey: "plaidAccessToken") else {
            print("⚠️ No access token in UserDefaults.")
            return
        }

        // 2) Compute date strings for one year ago → today
        let today = Date()
        let calendar = Calendar.current
        guard let oneYearAgoDate = calendar.date(byAdding: .year, value: -1, to: today) else {
            return
        }
        let endDateStr = isoDateFormatter.string(from: today)
        let startDateStr = isoDateFormatter.string(from: oneYearAgoDate)

        // 3) Call the new DataService method:
        DataService.loadTransactionsBetween(
            accessToken: token,
            startDate: startDateStr,
            endDate: endDateStr
        ) { [weak self] txs in
            guard let self = self else { return }
            self.allTransactions = txs
            self.groupTransactionsByMonth()
            self.tableView.reloadData()
        }
    }

    // MARK: – Grouping & Totals

    private func groupTransactionsByMonth() {
        transactionsByMonth.removeAll()
        monthTotals.removeAll()
        sortedMonthKeys.removeAll()
        
        // 1) Group each transaction under the “month start” (YYYY-MM-01)
        for tx in allTransactions {
            guard let fullDate = isoDateFormatter.date(from: tx.date) else {
                continue
            }

            // Compute the first day of that month
            let comps = Calendar.current.dateComponents([.year, .month], from: fullDate)
            let monthStart = Calendar.current.date(from: comps)!

            // Append to that month’s array
            if var existing = transactionsByMonth[monthStart] {
                existing.append(tx)
                transactionsByMonth[monthStart] = existing
            } else {
                transactionsByMonth[monthStart] = [tx]
            }
        }

        // 2) For each month, sort descending by date and compute the total
        for (monthStart, txArray) in transactionsByMonth {
            // Sort by descending date
            let sortedArray = txArray.sorted { lhs, rhs in
                guard
                    let lhsDate = isoDateFormatter.date(from: lhs.date),
                    let rhsDate = isoDateFormatter.date(from: rhs.date)
                else {
                    return false
                }
                return lhsDate > rhsDate
            }
            transactionsByMonth[monthStart] = sortedArray

            // Compute total of `amount` for that month
            let totalForMonth = sortedArray.reduce(0.0) { partialSum, tx in
                return partialSum + tx.amount
            }
            monthTotals[monthStart] = totalForMonth
        }

        // 3) Sort the monthStart keys (descending, newest month first)
        sortedMonthKeys = transactionsByMonth.keys.sorted { lhs, rhs in
            return lhs > rhs
        }
    }
}

// MARK: – UITableViewDataSource

extension HistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedMonthKeys.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let monthStart = sortedMonthKeys[section]
        return monthHeaderFormatter.string(from: monthStart)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let monthStart = sortedMonthKeys[section]
        let countForMonth = transactionsByMonth[monthStart]?.count ?? 0
        // +1 for the “Monthly Total” row
        return countForMonth + 1
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let monthStart = sortedMonthKeys[indexPath.section]
        guard let monthArray = transactionsByMonth[monthStart] else {
            fatalError("No transactions for month \(monthStart)")
        }

        // If this is the last row in the section, show the “Monthly Total”
        let isTotalRow = (indexPath.row == monthArray.count)
        if isTotalRow {
            // Dequeue a standard cell with .value1 style for “Total”
            let cellID = "MonthTotalCell"
            let cell: UITableViewCell
            if let reused = tableView.dequeueReusableCell(withIdentifier: cellID) {
                cell = reused
            } else {
                cell = UITableViewCell(style: .value1, reuseIdentifier: cellID)
                cell.selectionStyle = .none
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            }
            cell.textLabel?.text = "Monthly Total"
            
            if let total = monthTotals[monthStart] {
                // Format total as currency, e.g. “$1,234.56”
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                cell.detailTextLabel?.text = formatter.string(from: NSNumber(value: total))
            } else {
                cell.detailTextLabel?.text = nil
            }
            return cell
        }

        // Otherwise, it’s a normal transaction row:
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TransactionCellView.reuseID,
                for: indexPath
            ) as? TransactionCellView
        else {
            fatalError("Unable to dequeue TransactionCellView")
        }
        let tx = monthArray[indexPath.row]
        cell.configure(with: tx)
        return cell
    }
}


