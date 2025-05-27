//
//  TransactionCellView.swift
//  Finance App
//
//  Created by Jas  on 5/22/25.
//

import UIKit

class TransactionCellView: UITableViewCell {
    
    static let reuseID = "TransactionCell"//reuse identifier for cell
    
    // MARK: UI
    private let nameLabel = UILabel()//label for transaction name (eg:Starbucks)
    private let detailLabel = UILabel()//label for date and dollar amount (eg: 2025-05-18 $1000)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {//initializer for custom UITableViewCell
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)//larger and bolder for title
        detailLabel.font = .systemFont(ofSize: 14, weight: .regular)//smaller and lighter for detail
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 2//how many lines of detailed label is allowed
        accessoryType = .disclosureIndicator
        
//      stack the labels vertically
        let stack = UIStackView(arrangedSubviews: [nameLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 4
        contentView.addSubview(stack)//add stack to the view
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }//this means this cell can be access only through storyboard
    
    func configure(with tx: Transaction) {//Populate the cell labels using transaction data from the api
        nameLabel.text = tx.name
        detailLabel.text = "\(tx.category) • \(tx.date) • $\(String(format: "%.2f", tx.amount))"
    }
}
