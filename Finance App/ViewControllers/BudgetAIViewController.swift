//
//  BudgetAIViewController.swift
//  Finance App
//
//  Created by Jas  on 6/17/25.
//

import UIKit

class BudgetAIViewController: UIViewController {

    // MARK: – UI
    private let scrollView = UIScrollView()
    private let stackView  = UIStackView()
    private let budgetLabel = UILabel()
    private let budgetInput = ModernSlider()
    private let budgetTextField: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        tf.borderStyle = .roundedRect
        tf.placeholder = "Enter amount"
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return tf
    }()
    private let generateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Generate Budget", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }()

    // MARK: – State
    private var weeklyBudget: Int = 100 {
        didSet {
            budgetLabel.text = "Based on $\(weeklyBudget) budget"
        }
    }
    private var suggestions: [String: Any] = [:]

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Weekly Budget"
        view.backgroundColor = .systemBackground
        setupViews()
        setupKeyboardAccessory()
    }

    // MARK: – Setup
    private func setupViews() {
        setupScrollAndStack()
        let budgetStack = makeBudgetControls()
        stackView.addArrangedSubview(budgetStack)
        setupConstraints()
    }

    private func setupScrollAndStack() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
    }

    private func makeBudgetControls() -> UIStackView {
        // — Label —
        budgetLabel.font = .systemFont(ofSize: 16, weight: .medium)
        budgetLabel.textColor = .secondaryLabel
        budgetLabel.textAlignment = .center
        budgetLabel.text = "Based on $\(weeklyBudget) budget"

        // — Text field —
        budgetTextField.text = "\(weeklyBudget)"
        budgetTextField.addTarget(
          self,
          action: #selector(budgetTextFieldChanged),
          for: .editingDidEnd
        )

        // — Slider —
        budgetInput.minimumValue = 0
        budgetInput.maximumValue = 500
        budgetInput.value        = Float(weeklyBudget)
        budgetInput.isContinuous = true
        budgetInput.minimumTrackTintColor = .systemGreen
        budgetInput.maximumTrackTintColor = .tertiarySystemFill
        budgetInput.thumbTintColor       = .systemBackground
        budgetInput.setThumbImage(
          UIImage(systemName: "circle.fill")?
            .withTintColor(.systemGreen, renderingMode: .alwaysOriginal),
          for: .normal
        )
        budgetInput.addTarget(
          self,
          action: #selector(budgetChanged(_:)),
          for: .valueChanged
        )

        // — Generate button —
        generateButton.addTarget(
          self,
          action: #selector(didTapGenerate),
          for: .touchUpInside
        )

        // — Stack them —
        let stack = UIStackView(
          arrangedSubviews: [budgetLabel,
                             budgetTextField,
                             budgetInput,
                             generateButton]
        )
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        // 🎨 — Polish into a card —
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
        stack.layoutMargins = UIEdgeInsets(
          top: 12, left: 16, bottom: 12, right: 16
        )
        stack.isLayoutMarginsRelativeArrangement = true

        return stack
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
              equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(
              equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(
              equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(
              equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(
              equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(
              equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(
              equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(
              equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(
              equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    // MARK: – Actions

    /// Snap slider to 10s, update label & text field (no fetch yet)
    @objc private func budgetChanged(_ slider: UISlider) {
        let step: Float = 10
        let rounded = round(slider.value / step) * step
        slider.value = rounded
        let val = Int(rounded)
        budgetTextField.text = "\(val)"
        budgetLabel.text = "Based on $\(val) budget"
    }

    /// Sync from text field into slider & label (no fetch yet)
    @objc private func budgetTextFieldChanged() {
        guard
          let txt = budgetTextField.text,
          let val = Int(txt),
          val >= Int(budgetInput.minimumValue),
          val <= Int(budgetInput.maximumValue)
        else { return }
        budgetInput.value = Float(val)
        budgetLabel.text = "Based on $\(val) budget"
    }

    /// Dismiss keyboard accessory
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Called when “Generate Budget” is tapped
    @objc private func didTapGenerate() {
        // 1️⃣ Dismiss keyboard
        view.endEditing(true)

        // 2️⃣ Capture the final value
        let final = Int(budgetInput.value)
        weeklyBudget = final
        budgetTextField.text = "\(final)"

        // 3️⃣ Fire the fetch
        print("🔄 Generating with budget:", final)
        fetchAISuggestions()
    }

    // MARK: – Fetch & Render

    private func fetchAISuggestions() {
        DataService.fetchAISummary(budget: weeklyBudget) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.suggestions = data
                    self.renderSuggestionCards()
                case .failure(let err):
                    print("❌ Failed to fetch:", err)
                }
            }
        }
    }

    private func renderSuggestionCards() {
        while stackView.arrangedSubviews.count > 1 {
            stackView.arrangedSubviews[1].removeFromSuperview()
        }
        for (key, value) in suggestions {
            let card = AISuggestionCardView()
            card.configure(title: key.capitalized, value: "$\(value)")
            stackView.addArrangedSubview(card)
        }
    }
}

// MARK: – Keyboard Accessory

private extension BudgetAIViewController {
    func setupKeyboardAccessory() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(
          barButtonSystemItem: .flexibleSpace,
          target: nil,
          action: nil
        )
        let done = UIBarButtonItem(
          title: "Done",
          style: .done,
          target: self,
          action: #selector(dismissKeyboard)
        )
        toolbar.items = [flex, done]
        budgetTextField.inputAccessoryView = toolbar
    }
}



