//
//  TitleHeaderView.swift
//  Finance App
//
//  Created by Jas  on 5/29/25.
//

import UIKit

/// A standalone header with a big title + chevron + profile button,
/// exposes a closure for the profile‐tap action.
class TitleHeaderView: UIControl {

    // MARK: - Public API

    /// Called when the user taps the profile icon
    var onProfileTap: (() -> Void)?
    var onDropdownTap: (() -> Void)?
    private var isOpen = false

    // MARK: - Subviews

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "My Accounts"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        return label
    }()

    private let chevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.down"))
        iv.tintColor = .label
        iv.contentMode = .center
        return iv
    }()

    private let profileButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let img = UIImage(systemName: "person.crop.circle", withConfiguration: cfg)
        btn.setImage(img, for: .normal)
        btn.tintColor = .secondaryLabel
        return btn
    }()

    private lazy var titleStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, chevron])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 4
        return s
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

    // MARK: - Setup

    private func setupViews() {
        addSubview(titleStack)
        addSubview(profileButton)
        profileButton.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)
        addTarget(self, action: #selector(handleTitleTap), for: .touchUpInside)
    }

    private func setupConstraints() {
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        profileButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // pin the stack to the left & full vertical
            titleStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleStack.topAnchor.constraint(equalTo: topAnchor),
            titleStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            // pin the profile icon to the right, centered on the stack
            profileButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileButton.centerYAnchor.constraint(equalTo: titleStack.centerYAnchor)
        ])
    }
    
    override var isHighlighted: Bool {
      didSet {
        let scale: CGFloat = isHighlighted ? 0.97 : 1.0
        UIView.animate(
          withDuration: 0.1,
          delay: 0,
          options: [.allowUserInteraction],
          animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
          },
          completion: { _ in
            if !self.isHighlighted { self.transform = .identity }
          }
        )
      }
    }


    // MARK: - Actions

    @objc private func handleProfileTap() {
        onProfileTap?()
    }
    
    @objc private func handleTitleTap() {
        // 1) Toggle open/closed
            isOpen.toggle()
            
            // 2) Animate the chevron 180° (π) when open, back to 0 when closed
            let angle: CGFloat = isOpen ? .pi : 0
            UIView.animate(
              withDuration: 0.2,
              delay: 0,
              options: [.curveEaseInOut],
              animations: {
                self.chevron.transform = CGAffineTransform(rotationAngle: angle)
              },
              completion: nil
            )
            
            // 3) Let the VC know (e.g. to show/hide your dropdown)
            onDropdownTap?()
    }
}


