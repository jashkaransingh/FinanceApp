//
//  FloatingActionButton.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class FloatingActionButton: UIButton {
    override init(frame: CGRect) {// this initializer means that the button is created in code
        super.init(frame: frame)
        setupStyle()
    }
    required init?(coder: NSCoder) { fatalError() } // this means that the button is used only programmatically not via storyboard
    
    private func setupStyle() {
        backgroundColor = .label // black button with white plus
        tintColor = .systemBackground
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let name: String
        if #available(iOS 18.0, *) {
            name = "apple.intelligence"
        } else {
            name = "sparkles" // simple, supported everywhere
        }
        let intelligence = UIImage(systemName: name, withConfiguration: config)
        setImage(intelligence, for: .normal)
        layer.cornerRadius = 28    // half of width/height
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 56).isActive = true
        heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
}

