//
//  OnboardingContentViewController.swift
//  Finance App
//
//  Created by Jas  on 7/31/25.
//

import UIKit
import Lottie

final class OnboardingContentViewController: UIViewController {
    
    // MARK: - Properties
    
    private let page: OnboardingPage
    
    // MARK: - UI Components
    
    // --- 1. NEW: The Glass Card view ---
    private let glassCard: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop // Make the animation loop
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headlineLabel: UILabel = {
        let label = UILabel()
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1)
        if let boldFontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) {
            label.font = UIFont(descriptor: boldFontDescriptor, size: 0) // size 0 preserves dynamic type
        } else {
            label.font = .preferredFont(forTextStyle: .title1) // Fallback
        }
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private let subtextLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - Initializer
    
    init(page: OnboardingPage) {
        self.page = page
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    // --- 2. UPDATED: The entire setupUI method ---
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure the views with data from our 'page' model
        animationView.animation = LottieAnimation.named(page.lottieAnimationName)
        headlineLabel.text = page.headline
        subtextLabel.text = page.subtext
        
        // 4. Play the animation
        animationView.play()
        
        // Create a dedicated stack for just the text
        let textStackView = UIStackView(arrangedSubviews: [headlineLabel, subtextLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 12
        textStackView.alignment = .center
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the subviews to the correct containers
        view.addSubview(animationView)
        view.addSubview(glassCard)
        glassCard.contentView.addSubview(textStackView) // Add textStack to the card's content view
        
        // Set up constraints for the new layout
        NSLayoutConstraint.activate([
            // Image View Constraints (centered in the top half of the screen)
            animationView.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            
            // Glass Card Constraints (below the image)
            glassCard.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 40),
            glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Text Stack Constraints (inside the glass card with padding)
            textStackView.topAnchor.constraint(equalTo: glassCard.contentView.topAnchor, constant: 24),
            textStackView.bottomAnchor.constraint(equalTo: glassCard.contentView.bottomAnchor, constant: -24),
            textStackView.leadingAnchor.constraint(equalTo: glassCard.contentView.leadingAnchor, constant: 16),
            textStackView.trailingAnchor.constraint(equalTo: glassCard.contentView.trailingAnchor, constant: -16)
        ])
    }
}
