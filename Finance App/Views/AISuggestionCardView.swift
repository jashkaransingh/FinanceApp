//
//  AISuggestionCardView.swift
//  Finance App
//
//  Created by Jas  on 6/17/25.
//

import UIKit

class AISuggestionCardView: UIView {
  private let iconView = UIImageView()
  private let titleLabel = UILabel()
  private let valueLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  required init?(coder: NSCoder) { fatalError() }

  /// Call this to fill the card
  func configure(title: String, value: String) {
    // 1) Pick an SF Symbol for the category (fallback: "tag.fill")
    let symbolName: String
    switch title.lowercased() {
      case "subway":      symbolName = "tram.fill"
      case "mcdonalds":   symbolName = "fork.knife"
      case "groceries":   symbolName = "cart.fill"
      case "bars":        symbolName = "wineglass.fill"
      default:            symbolName = "tag.fill"
    }
    iconView.image = UIImage(systemName: symbolName)
    titleLabel.text = title
    valueLabel.text = value
  }

  private func setup() {
    // card appearance
    backgroundColor = .secondarySystemBackground
    layer.cornerRadius  = 12
    layer.shadowColor   = UIColor.black.cgColor
    layer.shadowOpacity = 0.05
    layer.shadowOffset  = .init(width: 0, height: 2)
    layer.shadowRadius  = 4

    // icon
    iconView.tintColor = .systemBlue
    iconView.contentMode = .scaleAspectFit
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.setContentHuggingPriority(.required, for: .horizontal)

    // labels
    titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
    titleLabel.textColor = .label

    valueLabel.font = .systemFont(ofSize: 16, weight: .regular)
    valueLabel.textColor = .label

    // layout
    let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
    textStack.axis = .vertical
    textStack.spacing = 4

    let hStack = UIStackView(arrangedSubviews: [iconView, textStack])
    hStack.axis = .horizontal
    hStack.spacing = 12
    hStack.alignment = .center
    hStack.translatesAutoresizingMaskIntoConstraints = false

    addSubview(hStack)
    NSLayoutConstraint.activate([
      hStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      iconView.widthAnchor.constraint(equalToConstant: 28),
      iconView.heightAnchor.constraint(equalToConstant: 28)
    ])
  }
}


