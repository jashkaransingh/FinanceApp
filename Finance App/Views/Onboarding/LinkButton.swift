//
//  LinkButton.swift
//  Finance App
//
//  Created by Jas  on 5/27/25.
//

import Foundation

import UIKit

class LinkButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .normal)
        titleLabel?.font = .systemFont(ofSize: 14)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

