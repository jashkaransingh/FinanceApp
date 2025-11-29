//
//  HabitCell.swift
//  Finance App
//
//  Created by Jas  on 11/27/25.
//

import UIKit

/// A single row in the 'BudgetHabitSelectorViewController'.
/// Shows a merchant's name, details, and a checkbox.
final class HabitCell: UITableViewCell {
    
    // A unique identifier for registering the cell with the table view
    static let reuseID = "HabitCell"
    
    // MARK: - Public Properties
    
    /// A simple closure to notify the controller when the state changes
    var onToggle: ((Bool) -> Void)?
    
    private(set) var isChecked: Bool = false
    
    // MARK: - UI Elements
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .label
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var checkboxButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22)
        
        let unselectedImage = UIImage(systemName: "circle", withConfiguration: config)
        let selectedImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        
        button.setImage(unselectedImage, for: .normal)
        button.setImage(selectedImage, for: .selected)
        
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapCheckbox), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with data from a FrequentMerchant
    func configure(with merchant: FrequentMerchant, isSelected: Bool) {
        nameLabel.text = merchant.name
        let cost = String(format: "%.2f", merchant.medianCost)
        detailsLabel.text = "Approx. $\(cost) per visit"
        iconImageView.image = icon(for: merchant.category)
        
        setChecked(isSelected, animated: false)
    }
    
    /// Toggles the cell's selected state
    func setChecked(_ selected: Bool, animated: Bool = true) {
        self.isChecked = selected
        
        if animated {
            UIView.animate(withDuration: 0.1) {
                self.checkboxButton.isSelected = selected
            }
        } else {
            self.checkboxButton.isSelected = selected
        }
    }
    
    // MARK: - Actions
    
    @objc func didTapCheckbox() {
        setChecked(!isChecked)
        onToggle?(isChecked)
    }

    // MARK: - Private Setup
    
    private func setupLayout() {
        // We'll stack the labels vertically
        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailsLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        // Put everything in a horizontal stack
        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack, checkboxButton])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            // Constrain the icon
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            // Constrain the checkbox
            checkboxButton.widthAnchor.constraint(equalToConstant: 30),
            
            // Constrain the main stack to the cell's content view
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    /// A helper function to select an appropriate SF Symbol for a given category title.
    private func icon(for category: String) -> UIImage? {
        let symbolName: String
        switch category.lowercased() {
        case "food", "food & drink", "food_and_drink":
            symbolName = "fork.knife"
        case "transportation":
            symbolName = "car.fill"
        case "entertainment", "recreation":
            symbolName = "film.fill"
        case "shopping", "shops":
            symbolName = "bag.fill"
        case "payment", "debt payments":
            symbolName = "creditcard.fill"
        case "savings", "savings/emergency", "savings/investments":
            symbolName = "banknote.fill"
        default:
            symbolName = "tag.fill"
        }
        return UIImage(systemName: symbolName)
    }
}
