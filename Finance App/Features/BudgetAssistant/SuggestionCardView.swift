//
//  SuggestionCardView.swift
//  Finance App
//
//  Created by Jas  on 6/21/25.
//

import UIKit

/// Card view representing a single merchant with an adjustable visit count.
final class SuggestionCardView: UIView {
    
    // MARK: - Public Properties
    
    /// Called whenever the stepper value changes.
    var onStepperChanged: ((Int) -> Void)?
    
    /// Integer representation of the current stepper value.
    var currentVisitCount: Int {
        return Int(stepper.value)
    }
    
    /// Cost per visit for the current merchant.
    var costPerVisit: Double {
        return planItem?.costPerVisit ?? 0
    }
    
    /// The current plan item associated with this card.
    private(set) var planItem: BudgetPlanItem?
    
    // MARK: - UI Elements
    
    let titleLabel = UILabel()
    let amountLabel = UILabel()
    let subtitleLabel = UILabel()
    
    private let iconView = UIImageView()
    
    private lazy var visitCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 28).isActive = true
        return label
    }()
    
    private lazy var stepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 20
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.addTarget(self, action: #selector(stepperDidChange), for: .valueChanged)
        return stepper
    }()
    
    private let controlStack = UIStackView()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupSubviews()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public API
    
    /// Configures the card with the provided merchant and plan item.
    func configure(name: String, item: BudgetPlanItem) {
        planItem = item
        
        titleLabel.text = name
        iconView.image = icon(for: item.category)
        backgroundColor = color(for: item.category)
        
        stepper.value = Double(item.visits)
        updateAmounts(amount: item.amount, visits: item.visits)
    }
    
    /// Updates the displayed amounts and visit count.
    func updateAmounts(amount: Int, visits: Int) {
        amountLabel.text = "$\(amount)"
        visitCountLabel.text = "\(visits)"
        
        if titleLabel.text?.lowercased() != "buffer" {
            let cost = planItem?.costPerVisit ?? 0
            let visitWord = (visits == 1) ? "visit" : "visits"
            subtitleLabel.text = "\(visits) \(visitWord) at $\(String(format: "%.2f", cost))/visit"
        }
        
        // Prevents triggering onStepperChanged while programmatically updating the stepper.
        stepper.removeTarget(self, action: #selector(stepperDidChange), for: .valueChanged)
        stepper.value = Double(visits)
        stepper.addTarget(self, action: #selector(stepperDidChange), for: .valueChanged)
    }
    
    /// Brief shake animation used to indicate an invalid change.
    func jiggle() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - 5, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + 5, y: center.y))
        layer.add(animation, forKey: "position")
    }
    
    // MARK: - Private Setup
    
    private func setupView() {
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupSubviews() {
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        
        amountLabel.font = .systemFont(ofSize: 17, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .right
    }
    
    private func setupLayout() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let valueStack = UIStackView(arrangedSubviews: [amountLabel])
        valueStack.axis = .vertical
        valueStack.spacing = 2
        valueStack.alignment = .trailing
        
        let topStack = UIStackView(arrangedSubviews: [iconView, textStack, valueStack])
        topStack.axis = .horizontal
        topStack.spacing = 12
        topStack.alignment = .center
        
        controlStack.addArrangedSubview(visitCountLabel)
        controlStack.addArrangedSubview(stepper)
        controlStack.axis = .horizontal
        controlStack.spacing = 8
        controlStack.alignment = .center
        
        let mainCardStack = UIStackView(arrangedSubviews: [topStack, controlStack])
        mainCardStack.axis = .vertical
        mainCardStack.spacing = 16
        mainCardStack.distribution = .equalSpacing
        mainCardStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainCardStack)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            mainCardStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainCardStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainCardStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainCardStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    func hideStepperControls() {
        controlStack.isHidden = true
        subtitleLabel.text = "For one-off purchases"
    }
    
    /// Handles user-driven changes to the stepper value.
    @objc private func stepperDidChange() {
        let newVisitCount = Int(stepper.value)
        let newAmount = Int(round(costPerVisit * Double(newVisitCount)))
        
        updateAmounts(amount: newAmount, visits: newVisitCount)
        onStepperChanged?(newVisitCount)
    }
    
    // MARK: - Helpers
    
    private func icon(for title: String) -> UIImage? {
        let symbolName: String
        switch title.lowercased() {
        case "food", "food & dining", "food_and_drink":
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
    
    private func color(for title: String) -> UIColor {
        let colorName: String
        
        switch title.lowercased() {
        case "food", "food & dining":
            colorName = "FoodColor"
        case "transportation":
            colorName = "TransportColor"
        case "entertainment", "recreation":
            colorName = "EntertainmentColor"
        case "shopping":
            colorName = "ShoppingColor"
        case "savings", "savings/emergency", "savings/investments":
            colorName = "SavingsColor"
        default:
            colorName = "DefaultCardColor"
        }
        
        return UIColor(named: colorName) ?? .secondarySystemBackground
    }
}
