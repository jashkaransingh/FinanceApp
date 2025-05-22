//
//  AccountCardView.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class AccountCardView: UIView {
  // MARK: Subviews
  private let titleLabel = UILabel()
  private let amountLabel = UILabel()
  private let trendIcon = UIImageView()
  private let trendLabel = UILabel()
  private let subtitleLabel = UILabel()

  // MARK: Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .systemBackground
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
    titleLabel.text = model.periodTitle
    amountLabel.text = String(format: "$%.2f", model.amount)
    subtitleLabel.text = model.subtitle//subtitle - yesterday, lastweek

    if model.usesPieIcon {
      trendIcon.image = UIImage(systemName: "chart.pie.fill")
      trendLabel.isHidden = true
      trendIcon.tintColor = .black
    } else {
//    right now the percentage is hardcoded but "WILL HAVE TO DYNAMICALLY CALCULATE IT"
      let arrowName = model.percentage < 0 ? "arrow.down" : "arrow.up" //if the spending is less then arrow down else arrow up
      trendIcon.image = UIImage(systemName: arrowName)?.withRenderingMode(.alwaysTemplate)
      trendIcon.tintColor = .black
      trendLabel.text = "\(abs(model.percentage))%"
      trendLabel.isHidden = false
    }
  }

  // MARK: Layout
  private func setupSubviews() {
    [titleLabel, amountLabel, trendIcon, trendLabel, subtitleLabel]
      .forEach { addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
      titleLabel.font    = .systemFont(ofSize: 16, weight: .medium)
      amountLabel.font   = .systemFont(ofSize: 32, weight: .bold)
      trendLabel.font    = .systemFont(ofSize: 16, weight: .regular)
      subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),//padding - 12 from top
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),//padding - 16 from left

      amountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

      trendIcon.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
      trendIcon.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor, constant: 8),
      trendIcon.widthAnchor.constraint(equalToConstant: 16),
      trendIcon.heightAnchor.constraint(equalToConstant: 16),

      trendLabel.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
      trendLabel.leadingAnchor.constraint(equalTo: trendIcon.trailingAnchor, constant: 4),

      subtitleLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
    ])
  }
}

