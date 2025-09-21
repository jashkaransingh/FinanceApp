//
//  ModernTransactionCell.swift
//  Finance App
//
//  Created by Jas  on 6/5/25.
//

import UIKit

/// A “card”-style cell for one `Transaction`.
final class ModernTransactionCell: UITableViewCell {
    
    static let reuseID = "ModernTransactionCell"
    
    // MARK: - Subviews
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .label
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(style:reuseIdentifier:)") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        dateLabel.text = nil
        amountLabel.text = nil
    }
    
    // MARK: - Layout
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            // container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // name (top-left)
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            // amount (top-right)
            amountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            amountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // date (below name)
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        // Avoid squashing amount; allow name to truncate first.
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Shadow perf
        containerView.layer.shouldRasterize = true
        containerView.layer.rasterizationScale = UIScreen.main.scale
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Fixed shadow path for smoother scrolling
        containerView.layer.shadowPath = UIBezierPath(
            roundedRect: containerView.bounds,
            cornerRadius: containerView.layer.cornerRadius
        ).cgPath
    }
    
    // MARK: - Configure
    
    /// Populate name, date, and amount.
    func configure(with transaction: Transaction) {
        nameLabel.text = transaction.name
        
        if let d = AppFormatters.isoYMD.date(from: transaction.date) {
            dateLabel.text = AppFormatters.prettyMDY.string(from: d)
        } else {
            dateLabel.text = transaction.date
        }
        
        amountLabel.text = AppFormatters.currency.string(from: transaction.amount as NSNumber)
    }
}


