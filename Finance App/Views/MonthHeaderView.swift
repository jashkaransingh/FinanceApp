//
//  MonthHeaderView.swift
//  Finance App
//
//  Created by Jas  on 6/5/25.
//

import UIKit

/// A custom section header for each month.
/// Includes a blur effect behind the month label and a transparent white overlay.
class MonthHeaderView: UIView {
    static let reuseID = "MonthHeaderView"
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterialLight)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        backgroundColor = .secondarySystemBackground
//        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(blurView)
        blurView.contentView.addSubview(titleLabel)
        
        // Pin blurView with a small inset
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        // Pin titleLabel inside blurView, with padding
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set the month text, e.g. “June 2025”
    func configure(with monthStart: Date, formatter: DateFormatter) {
        titleLabel.text = formatter.string(from: monthStart)
    }
}

