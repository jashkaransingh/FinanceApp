//
//  ShimmerView.swift
//  Finance App
//
//  Created by Jas  on 6/10/25.
//

import UIKit

/// Simple shimmering placeholder view (skeleton loader).
final class ShimmerView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        gradientLayer.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations  = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
        // Intentionally not auto-starting; call startAnimating() when needed.
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        // Match rounded corners so the shimmer doesn't bleed past edges.
        gradientLayer.cornerRadius = layer.cornerRadius
    }
    
    // MARK: - Control
    
    func startAnimating() {
        // Avoid stacking duplicate animations.
        if gradientLayer.animation(forKey: "shimmer") != nil { return }
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue   = [1, 1.5, 2]
        animation.duration  = 1.2
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        gradientLayer.add(animation, forKey: "shimmer")
    }
    
    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}


