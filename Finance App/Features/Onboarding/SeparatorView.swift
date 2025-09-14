//
//  SeparatorView.swift
//  Finance App
//
//  Created by Jas  on 7/5/25.
//

import UIKit

class SeparatorView: UIView {

     let label: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let leftLine = UIView()
    private let rightLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        leftLine.backgroundColor = .systemGray4
        rightLine.backgroundColor = .systemGray4

        addSubview(label)
        addSubview(leftLine)
        addSubview(rightLine)

        label.translatesAutoresizingMaskIntoConstraints = false
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        rightLine.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),

            leftLine.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            leftLine.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -8),
            leftLine.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 1),

            rightLine.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            rightLine.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            rightLine.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            rightLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
