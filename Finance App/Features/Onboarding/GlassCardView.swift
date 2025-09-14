//
//  GlassCardView.swift
//  Finance App
//
//  Created by Jas  on 7/6/25.
//

import UIKit

/// A reusable view that provides a "glassmorphism" effect using system materials.
/// This upgraded version automatically adapts to light/dark mode and correctly
/// uses vibrancy for maximum content clarity.
final class GlassCardView: UIView {
    
    enum Appearance {
        case glass(dark: Bool = true, dimming: CGFloat = 0.20) // dimming 0…1
        case solid // optional escape hatch
    }
    
    // CRITICAL: We expose the blurView's actual contentView.
    // Add all subviews (labels, icons, etc.) to this view. This is essential
    // for the vibrancy effect, which makes content readable on the glass.
    public let contentView: UIView
    private let blurView: UIVisualEffectView
    private let dimView = UIView()
    private var appearance: Appearance
    
    init(appearance: Appearance = .glass()) {
        let effect = UIBlurEffect(style: .systemMaterial)
        self.blurView = UIVisualEffectView(effect: effect)
        self.contentView = blurView.contentView
        self.appearance = appearance
        super.init(frame: .zero)
        setupView()
        applyAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // shadow/border exactly as you have
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        
        blurView.layer.cornerRadius = 16
        blurView.clipsToBounds = true
        blurView.layer.borderWidth = 1.0
        blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor // slightly subtler
        
        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // NEW: a dim overlay to keep glass from looking washed out on black
        dimView.isUserInteractionEnabled = false
        dimView.backgroundColor = .clear
        dimView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(dimView)
        blurView.contentView.sendSubviewToBack(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
        ])
    }
    public func setAppearance(_ newAppearance: Appearance) {
        self.appearance = newAppearance
        applyAppearance()
    }

    private func applyAppearance() {
        switch appearance {
        case .glass(let dark, let dimming):
            blurView.effect = UIBlurEffect(style: dark ? .systemMaterialDark : .systemMaterial)
            blurView.backgroundColor = .clear
            dimView.backgroundColor = UIColor.black.withAlphaComponent(dimming.clamped(to: 0...0.5))
            
        case .solid:
            blurView.effect = nil
            blurView.backgroundColor = .secondarySystemGroupedBackground
            dimView.backgroundColor = .clear
        }
    }
}
private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}

