//
//  GlassCardView.swift
//  Finance App
//
//  Created by Jas  on 7/6/25.
//

import UIKit

class GlassCardView: UIView {

    let contentView: UIView = UIView()

    init() {
        super.init(frame: .zero)
        // Use a dark material for a "black glass" effect
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        
        backgroundColor = UIColor.white.withAlphaComponent(0.05) // Very subtle tint
        layer.cornerRadius = 24
        layer.masksToBounds = true
        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        layer.borderWidth = 1.0

        addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
}
