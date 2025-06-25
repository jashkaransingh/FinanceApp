//
//  SuggestionCardView.swift
//  Finance App
//
//  Created by Jas  on 6/21/25.
//

import UIKit

// This card shows the category title, an icon, example merchants, the allocated amount, and features an interactive slider for the user to reallocate their budget.

final class SuggestionCardView: UIView {
    
    // MARK: - Public Properties
    /// A closure that is called whenever the `budgetSlider`'s value changes.
    var onSliderChanged: ((Float) -> Void)?
    /// A computed property that provides integer access to the slider's current value.
    var currentAmount: Int {
        return Int(round(budgetSlider.value))
    }
    
    // MARK: - UI Elements
    // UI elements are made internal (the default) so the view controller can read their values if needed.
    let titleLabel = UILabel()
    let amountLabel = UILabel()
    let percentLabel = UILabel()
    let budgetSlider = UISlider()
    
    private let iconView = UIImageView()
    private let subtitleLabel = UILabel()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // All setup is consolidated into dedicated functions for cleanliness.
        setupView()
        setupSubviews()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    /// Configures the card's UI elements with data from a budget suggestion.
    /// - Parameters:
    ///   - title: The category name (e.g., "Food").
    ///   - subtitle: Example merchants for the category (e.g., "McDonald's, Starbucks").
    ///   - amount: The suggested budget amount for this category.
    ///   - percent: The percentage of the total budget this amount represents.
    func configure(title: String, subtitle: String, amount: Int, percent: Int) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        amountLabel.text = "$\(amount)"
        percentLabel.text = "\(percent)% of budget"
        
        // Set the slider's value based on the configured amount.
        budgetSlider.value = Float(amount)
        
        // Assign an appropriate icon based on the category title.
        iconView.image = icon(for: title)
    }
    
    // MARK: - Private Setup
    
    /// Sets up the main view's appearance.
    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    /// Configures the properties of all subviews.
    private func setupSubviews() {
        // Icon
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Labels
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        
        amountLabel.font = .systemFont(ofSize: 16, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .right
        
        percentLabel.font = .systemFont(ofSize: 12)
        percentLabel.textColor = .secondaryLabel
        percentLabel.textAlignment = .right
        
        // Interactive Budget Slider
        budgetSlider.maximumTrackTintColor = .systemGray4
        budgetSlider.tintColor = .systemBlue
        budgetSlider.translatesAutoresizingMaskIntoConstraints = false
        budgetSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        // To create a "thumb-less" slider that looks like a sleek progress bar,
        // we set a tiny, transparent image for its thumb.
        let thumbImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 15)).image { _ in }
        budgetSlider.setThumbImage(thumbImage, for: .normal)
        budgetSlider.setThumbImage(thumbImage, for: .highlighted)
    }
    
    /// Builds the view hierarchy and activates layout constraints.
    private func setupLayout() {
        // Build individual stack views for better organization.
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let valueStack = UIStackView(arrangedSubviews: [amountLabel, percentLabel])
        valueStack.axis = .vertical
        valueStack.spacing = 2
        valueStack.alignment = .trailing
        
        let topStack = UIStackView(arrangedSubviews: [iconView, textStack, valueStack])
        topStack.axis = .horizontal
        topStack.spacing = 12
        topStack.alignment = .center
        
        // Add all subviews to the main view.
        [topStack, budgetSlider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        // Activate all constraints.
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 100),
            
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            topStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            topStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            topStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            budgetSlider.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 8),
            budgetSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            budgetSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            budgetSlider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            budgetSlider.heightAnchor.constraint(equalToConstant: 20) // Keep the slider track thin.
        ])
    }
    
    // MARK: - Actions & Helpers
    
    /// Called when the slider's value is changed by the user.
    @objc private func sliderValueChanged(_ sender: UISlider) {
        // Pass the new value up to the controller via the callback.
        onSliderChanged?(sender.value)
    }
    
    /// A helper function to select an appropriate SF Symbol for a given category title.
    private func icon(for title: String) -> UIImage? {
        let symbolName: String
        switch title.lowercased() {
        case "food", "food & drink":
            symbolName = "fork.knife"
        case "transportation":
            symbolName = "car.fill"
        case "entertainment", "recreation":
            symbolName = "film.fill"
        case "shopping":
            symbolName = "bag.fill"
        case "debt payments":
            symbolName = "creditcard.fill"
        case "savings", "savings/emergency", "savings/investments":
            symbolName = "banknote.fill"
        default:
            // A sensible default for any other category.
            symbolName = "tag.fill"
        }
        return UIImage(systemName: symbolName)
    }
}
