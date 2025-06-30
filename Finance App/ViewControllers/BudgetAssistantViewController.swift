//
//  BudgetAssistantViewController.swift
//  Finance App
//
//  Created by Jas  on 6/21/25.
//

import UIKit

class BudgetAssistantViewController: UIViewController {
    
    // MARK: - Properties
    private var currentPlanTotalBudget: Int = 0
    private var originalTransactions: [Transaction] = []
    private var debounceTimer: Timer?
    
    // UI Elements
    private let activityIndicator = UIActivityIndicatorView(style: .large)
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
        setupView()
        loadSavedPlan()
    }
    
    // MARK: - UI Setup
    private func setupView() {
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupLayout()
        budgetSlider.addTarget(self, action: #selector(sliderDidChange), for: .valueChanged)
        
        // Start in the loading state by default
        contentStack.isHidden = true
        activityIndicator.startAnimating()
    }
    
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
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        
        // constraints
        NSLayoutConstraint.activate([
            // --- SCROLLER FIX: Pinning to correct guides ---
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
            
            // The rest of your constraints for the UI elements are correct
            headerIconContainer.widthAnchor.constraint(equalToConstant: 64),
            headerIconContainer.heightAnchor.constraint(equalToConstant: 64),
            headerIcon.centerXAnchor.constraint(equalTo: headerIconContainer.centerXAnchor),
            headerIcon.centerYAnchor.constraint(equalTo: headerIconContainer.centerYAnchor),
            headerIcon.widthAnchor.constraint(equalToConstant: 32),
            headerIcon.heightAnchor.constraint(equalToConstant: 32),
            
            budgetPill.heightAnchor.constraint(equalToConstant: 40),
            budgetPill.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            budgetPill.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            currencyIcon.leadingAnchor.constraint(equalTo: budgetPill.leadingAnchor, constant: 12),
            currencyIcon.centerYAnchor.constraint(equalTo: budgetPill.centerYAnchor),
            currencyIcon.widthAnchor.constraint(equalToConstant: 20),
            currencyIcon.heightAnchor.constraint(equalToConstant: 20),
            
            budgetValueLabel.centerXAnchor.constraint(equalTo: budgetPill.centerXAnchor),
            budgetValueLabel.centerYAnchor.constraint(equalTo: budgetPill.centerYAnchor),
            
            budgetSlider.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            budgetSlider.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            suggestionsStack.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            suggestionsStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            generateButton.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            generateButton.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Constraints for the central activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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
    /// Transitions the UI to the initial "Generate Plan" state.
    private func transitionToInitialState() {
        // Ensure suggestion views are hidden and cleared
        self.suggestionsHeader.isHidden = true
        self.suggestionsStack.isHidden = true
        self.suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        headerIconContainer.alpha = 1
        headerIconContainer.isHidden = false
        titleLabel.alpha = 1
        titleLabel.isHidden = false
        subtitleLabel.alpha = 1
        subtitleLabel.isHidden = false
        budgetPill.alpha = 1
        budgetPill.isHidden = false
        budgetSlider.alpha = 1
        budgetSlider.isHidden = false
        generateButton.alpha = 1
        generateButton.isHidden = false
        
        contentStack.alpha = 0
        contentStack.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.contentStack.alpha = 1
        }
    }
    /// Transitions the UI to show the budget plan cards.
    private func transitionToPlanState(plan: [String: CategoryBudget], totalBudget: Int) {
        // Ensure initial views are hidden
        self.headerIconContainer.isHidden = true
        self.titleLabel.isHidden = true
        self.subtitleLabel.isHidden = true
        self.budgetPill.isHidden = true
        self.budgetSlider.isHidden = true
        self.generateButton.isHidden = true
        
        // Update data
        self.currentPlanTotalBudget = totalBudget
        
        // CRITICAL: Add all cards to the stack *before* the animation block.
        // This allows the layout engine to calculate the final height of the content.
        let sortedCategories = plan.filter { $0.value.amount > 0 }.sorted { $0.key < $1.key }
        for (categoryName, budgetDetails) in sortedCategories {
            let card = SuggestionCardView()
            
            card.budgetSlider.maximumValue = Float(totalBudget)
            card.configure(
                title: categoryName.capitalized,
                subtitle: budgetDetails.subtitle,
                amount: budgetDetails.amount,
                percent: budgetDetails.percent
            )
            card.onSliderChanged = { [weak self] newValue in
                guard let self = self else { return }
                self.debounceTimer?.invalidate()
                self.debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                    self.reallocateBudgets(from: card, newValue: newValue)
                }
            }
            suggestionsStack.addArrangedSubview(card)
        }
        
        // Make the suggestion views visible
        self.suggestionsHeader.isHidden = false
        self.suggestionsStack.isHidden = false
        
        // Animate the entire content stack in smoothly.
        self.contentStack.alpha = 0
        self.contentStack.isHidden = false
        UIView.animate(withDuration: 0.4) {
            self.contentStack.alpha = 1
        }
    }
    
    // MARK: – Actions
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    // Called when the user drags the main budget slider.
    @objc private func sliderDidChange() {
        let v = Int(round(budgetSlider.value / 10) * 10)
        budgetSlider.value = Float(v)
        budgetValueLabel.text = "\(v)"
        
        if suggestionsHeader.isHidden == false {
            transitionToInitialState()
        }
    }
    
    /// Called when the user taps the "Generate My Plan" button. This is the main action trigger.
    @objc private func didTapGenerate() {
        // 1. Get the current budget value from the slider.
        let budget = Int(budgetSlider.value)
        
        // 2. Show a loading indicator on the button and disable it to prevent multiple taps.
        var config = generateButton.configuration ?? .plain()
        config.showsActivityIndicator = true
        generateButton.configuration = config
        generateButton.isEnabled = false
        
        loadSuggestions(for: budget)
    }
    
    
    // MARK: – Data Logic
    private func loadSavedPlan() {
        // The setInitialLoadingState() in viewDidLoad has already hidden all content
        // and started the main activityIndicator. We don't need to do anything else here.
        
        DataService.loadBudgetPlan { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // 1. Stop the main loading spinner.
                self.activityIndicator.stopAnimating()
                
                // 2. Based on the result, transition to the correct final UI state.
                switch result {
                case .success(let response):
                    // A plan was found. Transition to the plan view.
                    self.transitionToPlanState(plan: response.budgetPlan, totalBudget: response.totalBudget)
                    self.loadTransactionsInBackground()
                    
                case .failure:
                    // No plan found. Transition to the initial "Generate" view.
                    self.transitionToInitialState()
                }
            }
        }
    }
    /// This function starts the chain of network requests.
    private func loadSuggestions(for budget: Int) {
        // We no longer check for a token. We just fetch transactions.
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -42, to: endDate) else { return }
        
        let startDateString = iso8601(startDate)
        let endDateString = iso8601(endDate)
        
        DataService.loadTransactions(startDate: startDateString, endDate: endDateString) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let transactions):
                self.fetchAISuggestions(using: transactions, for: budget)
                
            case .failure(let error):
                print("❌ Failed to load transactions for AI: \(error)")
                DispatchQueue.main.async {
                    var config = self.generateButton.configuration ?? .plain()
                    config.showsActivityIndicator = false
                    self.generateButton.configuration = config
                    self.generateButton.isEnabled = true
                }
            }
        }
    }
    
    /// This function prepares the data and calls the AI endpoint via the DataService.
    private func fetchAISuggestions(using transactions: [Transaction], for budget: Int) {
        DataService.fetchAISuggestion(transactions: transactions, budget: budget) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                var config = self.generateButton.configuration ?? .plain()
                config.showsActivityIndicator = false
                self.generateButton.configuration = config
                self.generateButton.isEnabled = true
                
                switch result {
                case .success(let suggestionData):
                    self.originalTransactions = transactions
                    // Instead of calling render... directly, call the transition function
                    self.transitionToPlanState(plan: suggestionData, totalBudget: budget)
                    self.saveCurrentPlan(plan: suggestionData, totalBudget: budget)
                    
                case .failure(let error):
                    print("❌ AI fetching failed: \(error.localizedDescription)")
                    self.transitionToInitialState()
                }
            }
        }
    }
    
    // Delete the old reallocateBudgets function and replace it with this one.
    private func reallocateBudgets(from changedCard: SuggestionCardView, newValue: Float) {
        // 1. Get the current state of the plan directly from the UI cards.
        let allCards = suggestionsStack.arrangedSubviews.compactMap { $0 as? SuggestionCardView }
        let currentPlan = Dictionary(uniqueKeysWithValues: allCards.map {
            ($0.titleLabel.text ?? "", ["amount": $0.currentAmount])
        })
        
        guard let lockedCategory = changedCard.titleLabel.text else { return }
        
        // Optional: You could show a loading overlay here for better UX
        
        // 2. Call the DataService with the necessary info.
        DataService.fetchAIReallocation(
            transactions: self.originalTransactions,
            currentPlan: currentPlan,
            lockedCategory: lockedCategory,
            newValue: Int(round(newValue)),
            totalBudget: self.currentPlanTotalBudget
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newPlan):
                    self?.updateCards(with: newPlan)
                    self?.saveCurrentPlan(plan: newPlan, totalBudget: self?.currentPlanTotalBudget ?? 0)
                case .failure(let error):
                    print("❌ AI reallocation failed: \(error)")
                }
            }
        }
    }
    
    /// A small helper to save the current plan to the backend.
    private func saveCurrentPlan(plan: [String: CategoryBudget], totalBudget: Int) {
        DataService.saveBudgetPlan(plan: plan, totalBudget: totalBudget) { success in
            if success {
                print("✅ Budget plan saved successfully.")
            } else {
                print("❌ Failed to save budget plan.")
            }
        }
    }
    
    /// Fetches transactions quietly in the background so they are ready for reallocation.
    private func loadTransactionsInBackground() {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -42, to: endDate) else { return }
        let startDateString = iso8601(startDate)
        let endDateString = iso8601(endDate)
        
        DataService.loadTransactions(startDate: startDateString, endDate: endDateString) { [weak self] result in
            if case .success(let transactions) = result {
                self?.originalTransactions = transactions
                print("✅ Background transactions loaded for reallocation.")
            }
        }
    }
    
    // MARK: – Helpers
    
    /// Converts a Swift `Date` object into a "yyyy-MM-dd" string for API requests.
    private func iso8601(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        return fmt.string(from: date)
    }
    /// Updates the card UIs after an AI reallocation.
    private func updateCards(with newPlan: [String: CategoryBudget]) {
        let allCards = suggestionsStack.arrangedSubviews.compactMap { $0 as? SuggestionCardView }
        
        for card in allCards {
            guard let title = card.titleLabel.text,
                  let details = newPlan[title] else { // Matching by capitalized title
                continue
            }
            
            let newAmount = details.amount
            let newPercent = currentPlanTotalBudget > 0 ? Int((Float(newAmount) / Float(currentPlanTotalBudget)) * 100) : 0
            
            let originalCallback = card.onSliderChanged
            card.onSliderChanged = nil
            
            UIView.animate(withDuration: 0.3) {
                card.budgetSlider.setValue(Float(newAmount), animated: true)
            }
            card.amountLabel.text = "$\(newAmount)"
            card.percentLabel.text = "\(newPercent)% of budget"
            
            card.onSliderChanged = originalCallback
        }
    }
}

