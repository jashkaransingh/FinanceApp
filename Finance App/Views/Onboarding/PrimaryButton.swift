//
//  PrimaryButton.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

class PrimaryButton: UIButton {
    private let enabledBackground: UIColor  = .label
    private let disabledBackground: UIColor = .secondaryLabel
    private let enabledTitleColor: UIColor  = .systemBackground
    private let disabledTitleColor: UIColor = .tertiaryLabel
    
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        
        // This correctly becomes a black button on a light background
        backgroundColor = enabledBackground
        
        // This correctly becomes white text
        setTitleColor(enabledTitleColor, for: .normal)
        
        titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        layer.cornerRadius = 14
        heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? enabledBackground  : disabledBackground
            setTitleColor( isEnabled ? enabledTitleColor : disabledTitleColor,
                           for: .normal)
        }
    }
    
}
