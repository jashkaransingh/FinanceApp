//
//  LinkButton.swift
//  Finance App
//
//  Created by Jas  on 5/27/25.
//

import UIKit

class LinkButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 14)
        backgroundColor = .clear
        
        setTitleColor(.link, for: .normal)
        
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

