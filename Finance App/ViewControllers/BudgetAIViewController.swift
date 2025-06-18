//
//  BudgetAIViewController.swift
//  Finance App
//
//  Created by Jas  on 6/17/25.
//

import UIKit

class BudgetAIViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let budgetLabel = UILabel()
    private let budgetInput = UISlider()

    private var suggestions: [String: Any] = [:]
    private var weeklyBudget: Int = 100 {
        didSet {
            budgetLabel.text = "Based on $\(weeklyBudget) budget"
            fetchAISuggestions()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Weekly Budget"
        view.backgroundColor = .systemBackground
        setupViews()
        fetchAISuggestions()
    }

    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        budgetLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        budgetLabel.textColor = .secondaryLabel
        budgetLabel.text = "Based on $100 budget"
        budgetLabel.textAlignment = .center

        budgetInput.minimumTrackTintColor = .systemGreen
        budgetInput.maximumTrackTintColor = .tertiarySystemFill
        budgetInput.thumbTintColor       = .systemBackground
        budgetInput.setThumbImage(
          UIImage(systemName: "circle.fill")?
            .withTintColor(.systemGreen, renderingMode: .alwaysOriginal),
          for: .normal)

        let budgetStack = UIStackView(arrangedSubviews: [budgetLabel, budgetInput])
        budgetStack.axis = .vertical
        budgetStack.spacing = 8
        budgetStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(budgetStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    @objc private func budgetChanged() {
        weeklyBudget = Int(budgetInput.value)
    }

    private func fetchAISuggestions() {
        DataService.fetchAISummary(budget: weeklyBudget) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.suggestions = data
                    self.renderSuggestionCards()
                case .failure(let error):
                    print("❌ Failed to fetch: \(error)")
                }
            }
        }
    }

    private func renderSuggestionCards() {
        // Clear everything except budget controls
        while stackView.arrangedSubviews.count > 1 {
            let viewToRemove = stackView.arrangedSubviews[1]
            viewToRemove.removeFromSuperview()
        }

        for (key, value) in suggestions {
            let card = AISuggestionCardView()
            card.configure(title: key.capitalized, value: "\(value)")
            stackView.addArrangedSubview(card)
        }
    }
}


