//
//  GradientBackgroundView.swift
//  Finance App
//
//  Created by Jas  on 8/5/25.
//

import UIKit

/// A view that displays a soft, slowly animating two-color gradient.
final class GradientBackgroundView: UIView {

    private let gradientLayer = CAGradientLayer()
    
    init() {
        super.init(frame: .zero)
        setupGradient()
        startAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
    }
    
    private func setupGradient() {
        // Define your soft gradient colors. These are just examples.
        // They will look good in both light and dark mode.
        let color1 = UIColor.systemGray3.withAlphaComponent(0.4).cgColor
        let color2 = UIColor.systemGray5.withAlphaComponent(0.4).cgColor

        gradientLayer.colors = [color1, color2]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        self.layer.addSublayer(gradientLayer)
    }
    
    private func startAnimation() {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 7.0 // A slow, gentle animation
        animation.autoreverses = true
        animation.repeatCount = .infinity
        
        // A slightly different end-state for the gradient
        let color1 = UIColor.systemGray5.withAlphaComponent(0.4).cgColor
        let color2 = UIColor.systemGray3.withAlphaComponent(0.4).cgColor
        animation.toValue = [color1, color2]
        
        gradientLayer.add(animation, forKey: "gradientAnimation")
    }
    func pauseAnimation() {
        guard gradientLayer.speed != 0 else { return } // already paused
        let pausedTime = gradientLayer.convertTime(CACurrentMediaTime(), from: nil)
        gradientLayer.speed = 0
        gradientLayer.timeOffset = pausedTime
    }

    func resumeAnimation() {
        guard gradientLayer.speed == 0 else { return } // already running
        let pausedTime = gradientLayer.timeOffset
        gradientLayer.speed = 1
        gradientLayer.timeOffset = 0
        let timeSincePause = gradientLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        gradientLayer.beginTime = timeSincePause
    }
}
