//
//  ProfileHeaderView.swift
//  Finance App
//
//  Created by Jas  on 8/5/25.
//

import UIKit

/// A view that displays a user's profile picture, name, and email.
/// It's a UIControl to be tappable.
final class ProfileHeaderView: UIControl {
    
    // MARK: - UI Properties
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30 // Half of the height/width
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "person.fill")
        imageView.tintColor = .systemGray
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        // Scales with Dynamic Type
        let base = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: base)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "chevron.right")?
                .applyingSymbolConfiguration(.init(pointSize: 15, weight: .semibold))
        )
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private let highlightOverlay: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        v.alpha = 0
        v.layer.cornerRadius = 12
        return v
    }()
    
    // --- ADDITION: A shimmer view for loading state ---
    private let shimmerView = ShimmerView()
    
    override var isHighlighted: Bool {
        didSet {
            let pressed = isHighlighted
            UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = pressed ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.highlightOverlay.alpha = pressed ? 1 : 0
            }
        }
    }
    
    // MARK: - Init
    
    init() {
        super.init(frame: .zero)
        setupViews()
        // --- ADDITION: Show loading state by default ---
        showLoadingState(true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    // --- ADDITION: The main configuration method ---
    /// Configures the view with data from a UserProfile object.
    func configure(with profile: UserProfile) {
        showLoadingState(false) // Stop loading now that we have data
        
        nameLabel.text = profile.name
        emailLabel.text = profile.email
        
        let avatarSize: CGFloat = 60
        renderAvatar(name: profile.name, email: profile.email)
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        accessibilityLabel = [profile.name, profile.email].compactMap { $0 }.joined(separator: ", ")
        accessibilityHint = "Opens account settings."
        profileImageView.layer.cornerRadius = avatarSize / 2
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        renderAvatar(name: nameLabel.text ?? "", email: emailLabel.text ?? "")
    }

    
    private func renderAvatar(name: String, email: String) {
        // Resolve dynamic system colors *for this view’s* trait
        let bg = UIColor.systemBackground.resolvedColor(with: traitCollection) // white in light, black in dark
        let fg = UIColor.label.resolvedColor(with: traitCollection)            // black in light, white in dark
        
        let avatarSize: CGFloat = 60
        profileImageView.image = MonogramAvatarRenderer.image(
            name: name,
            email: email,
            size: avatarSize,
            font: nil,
            textColor: fg,
            backgroundColor: bg
        )
        
        profileImageView.layer.cornerRadius = avatarSize / 2
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
    }
    
    
    
    // --- ADDITION: Method to handle loading state ---
    /// Toggles the shimmer animation and hides/shows content.
    func showLoadingState(_ isLoading: Bool) {
        if isLoading {
            nameLabel.alpha = 0
            emailLabel.alpha = 0
            shimmerView.startAnimating()
        } else {
            shimmerView.stopAnimating()
            nameLabel.alpha = 1
            emailLabel.alpha = 1
        }
        shimmerView.isHidden = !isLoading
    }
    
    
    // MARK: - Setup
    
    private func setupViews() {
        // --- MODIFICATION: Add shimmerView ---
        
        
        let textStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [profileImageView, textStack, accessoryImageView])
        mainStack.axis = .horizontal
        mainStack.spacing = 16
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.isUserInteractionEnabled = false
        
        addSubview(mainStack)
        addSubview(highlightOverlay)
        highlightOverlay.translatesAutoresizingMaskIntoConstraints = false
        accessoryImageView.setContentHuggingPriority(.required, for: .horizontal)
        accessoryImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Lock size for a crisp chevron
        NSLayoutConstraint.activate([
            accessoryImageView.widthAnchor.constraint(equalToConstant: 12),
            accessoryImageView.heightAnchor.constraint(equalToConstant: 20),
            
            highlightOverlay.topAnchor.constraint(equalTo: topAnchor),
            highlightOverlay.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            highlightOverlay.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            highlightOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // --- MODIFICATION: Add shimmerView to the hierarchy ---
        addSubview(shimmerView)
        shimmerView.isUserInteractionEnabled = false
        
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // --- ADDITION: Shimmer view constraints ---
            shimmerView.topAnchor.constraint(equalTo: textStack.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: textStack.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: textStack.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: textStack.bottomAnchor)
        ])
    }
}
