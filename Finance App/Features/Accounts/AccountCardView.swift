//
//  AccountCardView.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class AccountCardView: UIControl {
    var model: AccountSummary?
    // MARK: Subviews
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let trendIcon = UIImageView()
    private let trendLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronIcon = UIImageView()
    
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 8
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") } //This will make present the card through code only not in storyyboard
    
    // MARK: Configuration
    func configure(with model: AccountSummary) { //argument passes as model of type AccountSummary
        self.model = model
        titleLabel.text = model.periodTitle
        amountLabel.text = String(format: "$%.2f", model.amount)
        subtitleLabel.text = model.subtitle//subtitle - yesterday, lastweek
        chevronIcon.image = UIImage(systemName: "chevron.right")
        chevronIcon.tintColor = .tertiaryLabel
        
        
        trendLabel.isHidden = false
        trendIcon.isHidden  = false
        
        let isDown = model.percentage < 0      // down = better (spent less)
        let arrowName = isDown ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
        
        trendIcon.image = UIImage(systemName: arrowName)?.withRenderingMode(.alwaysTemplate)
        trendIcon.tintColor = .label
        
        // one decimal place to match your look, e.g. "78.9%"
        trendLabel.text = String(format: "%.1f%%", abs(model.percentage))
    }
    
    override var isHighlighted: Bool {
        didSet {
            // a quick scale‐down on touch‐down, then back to identity on release
            let scale: CGFloat = isHighlighted ? 0.97 : 1.0
            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                options: [.allowUserInteraction],
                animations: {
                    self.transform = CGAffineTransform(scaleX: scale, y: scale)
                    // optionally dim the background slightly:
                    // self.alpha = isHighlighted ? 0.8 : 1.0
                },
                completion: nil
            )
        }
    }
    
    
    // MARK: Layout
    private func setupSubviews() {
        [titleLabel, amountLabel, trendIcon, trendLabel, subtitleLabel, chevronIcon]
            .forEach { addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        
        titleLabel.font    = .systemFont(ofSize: 18, weight: .medium)
        amountLabel.font   = .systemFont(ofSize: 32, weight: .bold)
        trendLabel.font    = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        trendLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // keep everything single-line so card height stays predictable
        titleLabel.numberOfLines = 1
        amountLabel.numberOfLines = 1
        trendLabel.numberOfLines = 1
        subtitleLabel.numberOfLines = 1
        
        // stop labels from vertically stretching
        [titleLabel, amountLabel, trendLabel, subtitleLabel].forEach {
            $0.setContentHuggingPriority(.required, for: .vertical)
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }
    
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronIcon.leadingAnchor, constant: -8),
            
            // Chevron aligned with the title
            chevronIcon.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            chevronIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevronIcon.widthAnchor.constraint(equalToConstant: 12),
            chevronIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Amount — bigger gap from title (← tweak here if you want)
            amountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Trend inline with amount
            trendIcon.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
            trendIcon.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor, constant: 8),
            trendIcon.widthAnchor.constraint(equalToConstant: 20),
            trendIcon.heightAnchor.constraint(equalToConstant: 20),
            
            trendLabel.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
            trendLabel.leadingAnchor.constraint(equalTo: trendIcon.trailingAnchor, constant: 4),
            
            // Subtitle — tighter gap under amount (← tweak here if you want)
            subtitleLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }
    
}

