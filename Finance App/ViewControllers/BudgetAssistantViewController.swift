//
//  BudgetAssistantViewController.swift
//  Finance App
//
//  Created by Jas  on 6/21/25.
//

import UIKit

class BudgetAssistantViewController: UIViewController {
    
    // MARK: - Properties
    
    var accessToken: String? // To be passed from the previous screen
    private var currentPlanTotalBudget: Int = 0
    private var originalTransactions: [Transaction] = []
    private var debounceTimer: Timer?
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    
    // back button + title
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = .label
        btn.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        return btn
    }()
    
    // big target icon
    private let headerIconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 32
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let headerIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "target"))
        iv.tintColor = .label
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // title + subtitle
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Set Your Weekly Budget"
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "We'll suggest how to allocate your spending"
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
    
    // pill-shaped budget input
    private let budgetPill: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let currencyIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "dollarsign"))
        iv.tintColor = .secondaryLabel
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let budgetValueLabel: UILabel = {
        let l = UILabel()
        l.text = "200"
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // full-width slider + min/max labels
    private let budgetSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 50
        s.maximumValue = 1000
        s.value = 200
        s.minimumTrackTintColor = .label
        s.maximumTrackTintColor = .systemGray3
        s.thumbTintColor = .label
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    private let sliderMinLabel: UILabel = {
        let l = UILabel()
        l.text = "$50"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        return l
    }()
    private let sliderMaxLabel: UILabel = {
        let l = UILabel()
        l.text = "$1000"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        return l
    }()
    
    // generate Budget Button
    private lazy var generateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Generate My Plan", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.backgroundColor = .label
        btn.setTitleColor(.systemBackground, for: .normal)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapGenerate), for: .touchUpInside)
        return btn
    }()
    
    // “Your Spending Plan” header
    private lazy var suggestionsHeader: UIStackView = {
        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.tintColor = .systemGreen
        icon.setContentHuggingPriority(.required, for: .horizontal)
        
        let lbl = UILabel()
        lbl.text = "Your Spending Plan"
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = .label
        
        let stack = UIStackView(arrangedSubviews: [icon, lbl])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    // vertical list of cards
    private let suggestionsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        return s
    }()
    
    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupLayout()
        suggestionsHeader.isHidden = true
        suggestionsStack.isHidden = true
        budgetSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    }
    
    // MARK: - UI Setup
    private func setupNavBar() {
        title = "Budget Assistant"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        // Use a modern, adaptive appearance for the navigation bar.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupLayout() {
        // scroll + stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        [
            headerIconContainer,
            titleLabel,
            subtitleLabel,
            budgetPill,
            budgetSlider,
            makeSliderLabels(),
            generateButton,
            suggestionsHeader,
            suggestionsStack
        ].forEach { contentStack.addArrangedSubview($0) }
        
        // header icon
        headerIconContainer.addSubview(headerIcon)
        
        // pill contents
        budgetPill.addSubview(currencyIcon)
        budgetPill.addSubview(budgetValueLabel)
        
        // constraints
        NSLayoutConstraint.activate([
            // scrollView edges
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // stack inside scroll
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            // header icon container
            headerIconContainer.widthAnchor.constraint(equalToConstant: 64),
            headerIconContainer.heightAnchor.constraint(equalToConstant: 64),
            headerIcon.centerXAnchor.constraint(equalTo: headerIconContainer.centerXAnchor),
            headerIcon.centerYAnchor.constraint(equalTo: headerIconContainer.centerYAnchor),
            headerIcon.widthAnchor.constraint(equalToConstant: 32),
            headerIcon.heightAnchor.constraint(equalToConstant: 32),
            
            // pill size
            budgetPill.heightAnchor.constraint(equalToConstant: 40),
            budgetPill.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            budgetPill.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            // pill subviews
            currencyIcon.leadingAnchor.constraint(equalTo: budgetPill.leadingAnchor, constant: 12),
            currencyIcon.centerYAnchor.constraint(equalTo: budgetPill.centerYAnchor),
            currencyIcon.widthAnchor.constraint(equalToConstant: 20),
            currencyIcon.heightAnchor.constraint(equalToConstant: 20),
            
            budgetValueLabel.centerXAnchor.constraint(equalTo: budgetPill.centerXAnchor),
            budgetValueLabel.centerYAnchor.constraint(equalTo: budgetPill.centerYAnchor),
            
            // slider full width
            budgetSlider.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            budgetSlider.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            // suggestionsStack width
            suggestionsStack.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            suggestionsStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            // Add constraints for generate budget button
            generateButton.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            generateButton.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            generateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func makeSliderLabels() -> UIStackView {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let h = UIStackView(arrangedSubviews: [sliderMinLabel, spacer, sliderMaxLabel])
        h.axis = .horizontal
        h.translatesAutoresizingMaskIntoConstraints = false
        return h
    }
    
    // MARK: – Actions
    
    // Called when the user drags the main budget slider.
    @objc private func sliderChanged() {
        // Update the budget label
        let v = Int(round(budgetSlider.value / 10) * 10)
        budgetSlider.value = Float(v)
        budgetValueLabel.text = "\(v)"
        
        // If results are currently showing, hide them and bring back the Generate button.
        if suggestionsHeader.isHidden == false {
            // In sliderChanged, inside the existing animation block
            UIView.animate(withDuration: 0.3) {
                self.suggestionsHeader.isHidden = true
                self.suggestionsStack.isHidden = true
                self.generateButton.isHidden = false
                
                // Animate the top controls back into view
                self.titleLabel.isHidden = false
                self.subtitleLabel.isHidden = false
                self.headerIconContainer.isHidden = false
                self.budgetPill.isHidden = false
                
                self.suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            }
        }
    }
    
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    /// Called when the user taps the "Generate My Plan" button. This is the main action trigger.
    @objc private func didTapGenerate() {
        // 1. Get the current budget value from the slider.
        let budget = Int(budgetSlider.value)
        print("Generate button tapped with budget: \(budget)")
        
        // 2. Show a loading indicator on the button and disable it to prevent multiple taps.
        var config = generateButton.configuration ?? .plain()
        config.showsActivityIndicator = true
        generateButton.configuration = config
        generateButton.isEnabled = false
        
        // 3. Kick off the data fetching process.
        loadSuggestions(for: budget)
    }
    
    // MARK: – Data Logic
    /// This function starts the chain of network requests.
    private func loadSuggestions(for budget: Int) {
        // 1. Check for the Plaid access token. We can't do anything without it.
        guard let token = accessToken else {
            print("Error: Access token is missing.")
            // Re-enable the button if we can't proceed.
            var config = self.generateButton.configuration ?? .plain()
            config.showsActivityIndicator = false
            self.generateButton.configuration = config
            self.generateButton.isEnabled = true
            return
        }
        
        // 2. Define the date range for fetching historical transactions (last 42 days).
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -42, to: endDate) else { return }
        
        // 3. Call the DataService to fetch transactions from our backend.
        DataService.loadTransactions(
            accessToken: token,
            startDate: iso8601(startDate),
            endDate: iso8601(endDate)
        ) { [weak self] transactions in
            // Once transactions are fetched, this completion block is called.
            guard let self = self else { return }
            print("✅ Loaded \(transactions.count) transactions.")
            
            // 4. With the transactions loaded, now we call the AI.
            self.fetchAISuggestions(using: transactions, for: budget)
        }
    }
    
    /// This function prepares the data and calls the AI endpoint via the DataService.
    private func fetchAISuggestions(using transactions: [Transaction], for budget: Int) {
        // 1. Create the JSON payload to send to our backend.
        let payload: [String: Any] = [
            "weekly_budget": budget,
            "transactions": transactions.map { ["name": $0.name, "amount": $0.amount] }
        ]
        
        // 2. Call the AI summary endpoint in our DataService.
        DataService.fetchAISummary(payload: payload) { [weak self] result in
            // This completion block is called when the AI responds.
            // We must switch to the main thread to update the UI.
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // 3. Stop the loading animation on the button.
                var config = self.generateButton.configuration ?? .plain()
                config.showsActivityIndicator = false
                self.generateButton.configuration = config
                self.generateButton.isEnabled = true
                
                // 4. Handle the result from the AI.
                switch result {
                case .success(let data):
                    // If successful, render the suggestion cards on the screen.
                    print("✅ AI suggestions received: \(data)")
                    self.originalTransactions = transactions
                    self.renderSuggestionCards(from: data, totalBudget: budget)
                    
                case .failure(let error):
                    // If it fails, print an error and ensure the suggestions area is hidden.
                    print("❌ AI fetching failed: \(error.localizedDescription)")
                    self.suggestionsHeader.isHidden = true
                    self.suggestionsStack.isHidden = true
                }
            }
        }
    }
    
    /// Takes a new budget plan from the AI and updates all the visible cards to match.
    private func updateCards(with newPlan: [String: Any]) {
        // 1. Get a reference to all the SuggestionCardView instances currently on screen.
        let allCards = suggestionsStack.arrangedSubviews.compactMap { $0 as? SuggestionCardView }
        
        // 2. Loop through each card that is currently visible.
        for card in allCards {
            // 3. Find the new data for this specific card using its title as a key.
            guard let title = card.titleLabel.text,
                  let details = newPlan[title] as? [String: Any],
                  let newAmount = details["amount"] as? Int else {
                // If the AI didn't return data for this card, just skip it.
                continue
            }
            
            // 4. Calculate the new percentage based on the new amount.
            let newPercent = Int((Float(newAmount) / Float(self.currentPlanTotalBudget)) * 100)
            
            // 5. CRITICAL: To prevent an infinite loop, we temporarily remove the action
            //    from the slider before programmatically changing its value.
            card.budgetSlider.removeTarget(self, action: nil, for: .valueChanged)
            
            // 6. Update the card's UI with the new values from the AI.
            //    We can animate this for a smooth visual effect.
            UIView.animate(withDuration: 0.3) {
                card.budgetSlider.setValue(Float(newAmount), animated: true)
            }
            card.amountLabel.text = "$\(newAmount)"
            card.percentLabel.text = "\(newPercent)% of budget"
            
            // 7. CRITICAL: Re-attach the action to the slider so the user can move it again.
            card.budgetSlider.addTarget(self, action: #selector(sliderDidMove), for: .valueChanged)
        }
    }
    
    private func renderSuggestionCards(from suggestions: [String: Any], totalBudget: Int) {
        suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let filteredSuggestions = suggestions.filter {
            guard let details = $0.value as? [String: Any], let amount = details["amount"] as? Int else { return false }
            return amount > 0
        }
        
        if filteredSuggestions.isEmpty {
            suggestionsHeader.isHidden = true
            suggestionsStack.isHidden = true
            generateButton.isHidden = false // Show button again if no results
            return
        }
        self.currentPlanTotalBudget = totalBudget
        
        suggestionsHeader.isHidden = false
        suggestionsStack.isHidden = false
        generateButton.isHidden = true
        
        UIView.animate(withDuration: 0.4) {
            self.titleLabel.isHidden = true
            self.subtitleLabel.isHidden = true
            self.headerIconContainer.isHidden = true
            self.budgetPill.isHidden = true
        }
        
        // Create all cards first
        let cards = filteredSuggestions.map { (key, value) -> SuggestionCardView in
            let card = SuggestionCardView()
            guard let details = value as? [String: Any],
                  let amount = details["amount"] as? Int,
                  let percent = details["percent"] as? Int,
                  let subtitle = details["subtitle"] as? String else {
                return card // Return an empty card if data is malformed
            }
            // 1. Set the max value FIRST.
            card.budgetSlider.maximumValue = Float(totalBudget)
            
            // 2. Configure the card SECOND. This will now correctly set the initial value.
            card.configure(title: key.capitalized, subtitle: subtitle, amount: amount, percent: percent)
            return card
        }
        
        // Now, configure the callback for each card
        for card in cards {
            card.onSliderChanged = { [weak self] newValue in
                // When a slider moves...
                guard let self = self else { return }
                
                // 1. Invalidate any previous timer. This cancels the old API request if the user keeps moving the slider.
                self.debounceTimer?.invalidate()
                
                // 2. Start a new timer. The code inside will only run after 0.8 seconds of inactivity.
                self.debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                    // 3. Call our reallocation function, which triggers the smart AI.
                    self.reallocateBudgets(from: card, newValue: newValue)
                }
            }
            suggestionsStack.addArrangedSubview(card)
        }
    }
    
    // Delete the old reallocateBudgets function and replace it with this one.
    private func reallocateBudgets(from changedCard: SuggestionCardView, newValue: Float) {
        // 1. Get the current state of the plan from all cards
        var currentPlan: [String: [String: Any]] = [:]
        let allCards = suggestionsStack.arrangedSubviews.compactMap { $0 as? SuggestionCardView }
        for card in allCards {
            if let title = card.titleLabel.text {
                // We send the integer value of the slider, not a float
                currentPlan[title] = ["amount": card.currentAmount]
            }
        }
        
        // 2. Identify the category the user locked
        guard let lockedCategory = changedCard.titleLabel.text else { return }
        
        // 3. Show a loading indicator (optional but good UX)
        // You could add a spinner to the view here.
        
        // 4. Call the new DataService function
        DataService.fetchAIReallocation(
            transactions: self.originalTransactions,
            currentPlan: currentPlan,
            lockedCategory: lockedCategory,
            newValue: Int(round(newValue)),
            totalBudget: self.currentPlanTotalBudget
        ) { [weak self] result in
            DispatchQueue.main.async {
                // Hide loading indicator...
                switch result {
                case .success(let newPlan):
                    // When we get the new smart plan, update all cards.
                    self?.updateCards(with: newPlan)
                case .failure(let error):
                    print("❌ AI reallocation failed: \(error)")
                }
            }
        }
    }
    // In the Actions section...
    @objc private func sliderDidMove(_ sender: UISlider) {
        // This function is just a target for the re-attached slider action.
        // The actual logic is handled by the `onSliderChanged` closure.
    }
    // MARK: – Helpers
    
    /// Converts a Swift `Date` object into a "yyyy-MM-dd" string for API requests.
    private func iso8601(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        return fmt.string(from: date)
    }
}

