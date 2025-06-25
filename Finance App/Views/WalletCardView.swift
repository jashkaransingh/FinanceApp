//
//  WalletCardView.swift
//  Finance App
//
//  Created by Jas  on 6/21/25.
//

import UIKit

class WalletCardView: UIView {
  
  // MARK: – Public API
  
  /// Call this to configure the card’s content
  func configure(
    bankName: String,
    cardholder: String,
    maskedNumber: String,
    expiry: String,
    balance: Double,
    gradientColors: [UIColor]
  ) {
    bankLabel.text        = bankName
    nameLabel.text        = cardholder.uppercased()
    numberLabel.text      = maskedNumber
    expiryLabel.text      = expiry
    balanceLabel.text     = String(format: "$%.2f", balance)
    
    // update gradient
    gradientLayer.colors = gradientColors.map { $0.cgColor }
  }
  
  // MARK: – Subviews

  private let gradientLayer = CAGradientLayer()
  private let bankLabel: UILabel = {
    let l = UILabel()
    l.font = .systemFont(ofSize: 18, weight: .bold)
    l.textColor = .white
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()
  private let networkLogo: UIImageView = {
    let iv = UIImageView(image: UIImage(named: "card_network"))  // add your PNG asset
    iv.contentMode = .scaleAspectFit
    iv.tintColor = .white
    iv.translatesAutoresizingMaskIntoConstraints = false
    return iv
  }()
  private let chipImage: UIImageView = {
    let iv = UIImageView(image: UIImage(systemName: "creditcard.fill"))
    iv.tintColor = .white
    iv.translatesAutoresizingMaskIntoConstraints = false
    return iv
  }()
  private let numberLabel: UILabel = {
    let l = UILabel()
    l.font = .monospacedDigitSystemFont(ofSize: 20, weight: .medium)
    l.textColor = .white
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()
  private let nameLabel: UILabel = {
    let l = UILabel()
    l.font = .systemFont(ofSize: 14, weight: .medium)
    l.textColor = .white
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()
  private let expiryLabel: UILabel = {
    let l = UILabel()
    l.font = .systemFont(ofSize: 14, weight: .regular)
    l.textColor = .white
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()
  private let balanceLabel: UILabel = {
    let l = UILabel()
    l.font = .systemFont(ofSize: 24, weight: .semibold)
    l.textColor = .white
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()
  
  // MARK: – Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupAppearance()
    setupSubviews()
    setupConstraints()
  }
  
  required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
  
  // MARK: – Setup
  
  private func setupAppearance() {
    // gradient background
    layer.insertSublayer(gradientLayer, at: 0)
    layer.cornerRadius = 16
    layer.masksToBounds = true
    
    // card shadow
    layer.shadowColor   = UIColor.black.cgColor
    layer.shadowOpacity = 0.2
    layer.shadowOffset  = CGSize(width: 0, height: 4)
    layer.shadowRadius  = 8
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = bounds
  }
  
  private func setupSubviews() {
    [bankLabel, networkLogo,
     chipImage, numberLabel,
     nameLabel, expiryLabel,
     balanceLabel].forEach {
      addSubview($0)
    }
  }
  
  private func setupConstraints() {
    NSLayoutConstraint.activate([
      // top row: bank name & network logo
      bankLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      bankLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      
      networkLogo.centerYAnchor.constraint(equalTo: bankLabel.centerYAnchor),
      networkLogo.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      networkLogo.widthAnchor.constraint(equalToConstant: 40),
      networkLogo.heightAnchor.constraint(equalToConstant: 24),
      
      // chip icon
      chipImage.topAnchor.constraint(equalTo: bankLabel.bottomAnchor, constant: 20),
      chipImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      chipImage.widthAnchor.constraint(equalToConstant: 40),
      chipImage.heightAnchor.constraint(equalToConstant: 30),
      
      // card number
      numberLabel.centerYAnchor.constraint(equalTo: chipImage.centerYAnchor),
      numberLabel.leadingAnchor.constraint(equalTo: chipImage.trailingAnchor, constant: 12),
      numberLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      
      // name & expiry
      nameLabel.topAnchor.constraint(equalTo: chipImage.bottomAnchor, constant: 20),
      nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      
      expiryLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
      expiryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      
      // balance at bottom
      balanceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
      balanceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
    ])
  }
}

