//
//  FloatingActionButton.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

final class FloatingActionButton: UIButton {
    
    private enum Const {
        static let size: CGFloat = 56
        static var cornerRadius: CGFloat { size / 2 }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupStyle()
        setupSizeConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }
    
    // MARK: - Setup
    
    private func setupStyle() {
        backgroundColor = .label
        tintColor = .systemBackground
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let symbolName: String
        if #available(iOS 18.0, *) {
            symbolName = "apple.intelligence"
        } else {
            symbolName = "sparkles"
        }
        setImage(UIImage(systemName: symbolName, withConfiguration: config), for: .normal)
        
        layer.cornerRadius = Const.cornerRadius
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    private func setupSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Const.size),
            heightAnchor.constraint(equalToConstant: Const.size)
        ])
    }
}


