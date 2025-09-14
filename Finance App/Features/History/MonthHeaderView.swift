//
//  MonthHeaderView.swift
//  Finance App
//
//  Created by Jas  on 6/5/25.
//

import UIKit

/// A custom section header for each month.
/// Includes a blur effect behind the month label and a transparent white overlay.
final class MonthHeaderView: UIView {
    static let reuseID = "MonthHeaderView"

    private let bubble: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground // adapts perfectly
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubble)
        bubble.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bubble.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bubble.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bubble.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            titleLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: bubble.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with monthStart: Date, formatter: DateFormatter) {
        titleLabel.text = formatter.string(from: monthStart)
    }
}


