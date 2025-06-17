//
//  ShimmerView.swift
//  Finance App
//
//  Created by Jas  on 6/10/25.
//

import UIKit

class ShimmerView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        gradientLayer.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations  = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
        startAnimating()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue   = [1, 1.5, 2]
        animation.duration  = 1.2
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmer")
    }

    func stopAnimating() {
        gradientLayer.removeAllAnimations()
    }
}

