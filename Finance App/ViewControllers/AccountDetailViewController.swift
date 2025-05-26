//
//  AccountDetailViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class AccountDetailViewController: UIViewController {
    // MARK: – Public API
    var accessToken: String? //access token for plaid for user's bank data
    var period: String?            // set to "today", "week" or "month" before push
    
    // MARK: – UI
    private let tableView = UITableView()//for list of transaction
    private var transactions: [Transaction] = []//array for the fetched transaction data
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        guard let accessToken = accessToken, //to make sure values are set if not then crash
              let period = period else {
            fatalError("Required properties not set")
        }
        title = "\(period.capitalized)ʼs Spending"
        
        // 1) Setup & Layout your tableView to display transactions
        tableView.dataSource = self//assign this viewController as the dataSource for the table
        tableView.register(//register custom cell to reuse in table
            TransactionCellView.self,
            forCellReuseIdentifier: TransactionCellView.reuseID
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        //constraints for tableView
        NSLayoutConstraint.activate([//pins the table to all four side
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                                    ])
        
        // 2) Load transaction data for the selected period and refresh the table view
        DataService.loadTransactions(accessToken: accessToken, period: period) { [weak self] txs in
            self?.transactions = txs//once get the data store them in transaction aaray
            self?.tableView.reloadData()
        }
    }
}

// MARK: – UITableViewDataSource
extension AccountDetailViewController: UITableViewDataSource {//for supplying data to tableView
    func tableView(//this function returns no. of rows to display
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return transactions.count//in this case it's number of transaction
    }
    
    func tableView(//this method - cell to display at an index path
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(//using the TransactionCellView to display
            withIdentifier: TransactionCellView.reuseID,
            for: indexPath
        ) as? TransactionCellView else {
            fatalError("Unable to dequeue TransactionCellView")
        }
        cell.configure(with: transactions[indexPath.row])//populate the cell using the conigure method
        return cell
    }
}

