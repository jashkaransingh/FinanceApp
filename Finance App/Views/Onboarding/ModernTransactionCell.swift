//
//  ModernTransactionCell.swift
//  Finance App
//
//  Created by Jas  on 6/5/25.
//

import UIKit

/// A “card”-style cell for showing one Transaction.
/// Rounded corners, shadow, and padded content to look like a modern “tile.”
class ModernTransactionCell: UITableViewCell {
    static let reuseID = "ModernTransactionCell"
    
    // MARK: Subviews
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        l.textColor = .label
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(amountLabel)
        
        // Pin containerView  edge-to-edge with a bit of vertical padding
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // nameLabel at top-left
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8)
        ])
        
        // amountLabel at top-right
        NSLayoutConstraint.activate([
            amountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            amountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        // dateLabel below nameLabel
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12)
        ])
    }
    
    /// Call this to populate name, date, and amount
    func configure(with transaction: Transaction) {
        nameLabel.text = transaction.name
        
        // Format date as “Jun 03, 2025” instead of “2025-06-03”
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        if let d = df.date(from: transaction.date) {
            let out = DateFormatter()
            out.dateFormat = "MMM dd, yyyy"
            out.locale = Locale(identifier: "en_US_POSIX")
            dateLabel.text = out.string(from: d)
        } else {
            dateLabel.text = transaction.date
        }
        
        // Format amount as currency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        amountLabel.text = formatter.string(from: NSNumber(value: transaction.amount))
    }
}

