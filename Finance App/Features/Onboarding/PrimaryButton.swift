//
//  PrimaryButton.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

final class PrimaryButton: UIButton {
    
    private let enabledBackground: UIColor  = .label
    private let disabledBackground: UIColor = .secondaryLabel
    private let enabledTitleColor: UIColor  = .systemBackground
    private let disabledTitleColor: UIColor = .tertiaryLabel
    
    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        
        backgroundColor = enabledBackground
        setTitleColor(enabledTitleColor, for: .normal)
        
        layer.cornerRadius = 14
        heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(title:)") }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? enabledBackground : disabledBackground
            setTitleColor(isEnabled ? enabledTitleColor : disabledTitleColor, for: .normal)
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                self.transform = self.isHighlighted ? .init(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }
}


