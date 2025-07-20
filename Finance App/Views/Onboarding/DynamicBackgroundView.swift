//
//  DynamicBackgroundView.swift
//  Finance App
//
//  Created by Jas  on 7/7/25.
//

import UIKit

class DynamicBackgroundView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        
        // Create multiple glowing orbs
        createOrb(size: 300, initialCenter: CGPoint(x: bounds.width * 0.1, y: bounds.height * 0.2), delay: 0)
        createOrb(size: 250, initialCenter: CGPoint(x: bounds.width * 0.8, y: bounds.height * 0.8), delay: 1)

        // Add a blur layer over everything to make the orbs soft
        let blurEffect = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = self.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(visualEffectView)
    }

    private func createOrb(size: CGFloat, initialCenter: CGPoint, delay: TimeInterval) {
        let orb = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        
        // Create a radial gradient to make it glow
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = orb.bounds
        gradientLayer.type = .radial
        gradientLayer.colors = [UIColor.white.withAlphaComponent(0.4).cgColor, UIColor.clear.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        orb.layer.addSublayer(gradientLayer)
        
        orb.center = initialCenter
        insertSubview(orb, at: 0)
        
        // Animate the orb's position
        UIView.animate(withDuration: 15.0, delay: delay, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
            orb.center = CGPoint(x: self.bounds.width - orb.center.x, y: self.bounds.height - orb.center.y)
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // This is a simple way to get things started; for production, you might want more robust layout handling
        if subviews.count > 1 { // Ensure orbs are not recreated excessively
             return
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
