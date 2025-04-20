//
//  FloatingActionButton.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class FloatingActionButton: UIButton {
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupStyle()
  }
  required init?(coder: NSCoder) { fatalError() }

  private func setupStyle() {
    backgroundColor = .black
    tintColor = .white
    setImage(UIImage(systemName: "plus"), for: .normal)
    layer.cornerRadius = 28    // half of width/height
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.2
    layer.shadowRadius = 4
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: 56).isActive = true
    heightAnchor.constraint(equalToConstant: 56).isActive = true
  }
}

