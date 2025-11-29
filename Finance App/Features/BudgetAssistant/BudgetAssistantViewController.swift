//
//  BudgetAssistantViewController.swift
//  Finance App
//
//  Created by Jas  on 6/21/25.
//

import UIKit

class BudgetAssistantViewController: UIViewController {
    
    // MARK: - Properties
    private var currentPlan: [String: BudgetPlanItem] = [:]
    private var currentPlanTotalBudget: Int = 0
    private var debounceTimer: Timer?
    
    // MARK: - Data Properties
    private var allTransactions: [Transaction] = []
    private var selectedMerchants: [String]?
    var initialBudgetAmount: Int?
    
    // MARK: - UI Elements
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // Back button
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = .label
        btn.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        return btn
    }()
    
    // Header icon
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
    
    // Title and subtitle
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
    
    private lazy var budgetTextInput: UITextField = {
        let tf = UITextField()
        tf.text = "200" // Default starting value
        tf.font = .systemFont(ofSize: 72, weight: .bold)
        tf.textColor = .label
        tf.textAlignment = .center
        tf.keyboardType = .numberPad
        tf.addDoneToolbar()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.addTarget(self, action: #selector(budgetTextDidChange), for: .editingChanged)
        return tf
    }()
    
    // Generate budget button
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
    
    private lazy var editBudgetFAB: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        btn.setImage(UIImage(systemName: "applepencil.gen1", withConfiguration: config), for: .normal)
        btn.tintColor = .systemBackground
        btn.backgroundColor = .label
        
        btn.layer.cornerRadius = 28
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowRadius = 8
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        btn.addTarget(self, action: #selector(didTapStartOver), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
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
    
    // Vertical list of suggestion cards
    private let suggestionsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        return s
    }()
    
    init(transactions: [Transaction], selectedMerchants: [String]?) {
        self.allTransactions = transactions
        self.selectedMerchants = selectedMerchants
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        if selectedMerchants != nil {
            // Arrived from the habit selector with transactions already loaded.
            transitionToInitialState()
            activityIndicator.stopAnimating()
            
            if let initialBudgetAmount {
                budgetTextInput.text = "\(initialBudgetAmount)"
            }
        } else {
            // Arrived from the dashboard; load any existing saved plan.
            loadSavedPlan()
        }
    }
    
    // MARK: - UI Setup
    private func setupView() {
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupLayout()
        contentStack.isHidden = true
        activityIndicator.startAnimating()
    }
    
    private func setupNavBar() {
        title = "Budget Assistant"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupLayout() {
        // Configure scroll view and main content stack.
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
            budgetTextInput,
            generateButton,
            suggestionsHeader,
            suggestionsStack
        ].forEach { contentStack.addArrangedSubview($0) }
        
        headerIconContainer.addSubview(headerIcon)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        view.addSubview(editBudgetFAB)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
            
            headerIconContainer.widthAnchor.constraint(equalToConstant: 64),
            headerIconContainer.heightAnchor.constraint(equalToConstant: 64),
            headerIcon.centerXAnchor.constraint(equalTo: headerIconContainer.centerXAnchor),
            headerIcon.centerYAnchor.constraint(equalTo: headerIconContainer.centerYAnchor),
            headerIcon.widthAnchor.constraint(equalToConstant: 32),
            headerIcon.heightAnchor.constraint(equalToConstant: 32),
            
            budgetTextInput.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            budgetTextInput.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            suggestionsStack.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            suggestionsStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            
            generateButton.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            generateButton.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            editBudgetFAB.widthAnchor.constraint(equalToConstant: 56),
            editBudgetFAB.heightAnchor.constraint(equalToConstant: 56),
            editBudgetFAB.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editBudgetFAB.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    
    /// Transitions the UI to the initial "Generate Plan" state.
    private func transitionToInitialState() {
        // Hide and clear any existing suggestion views
        suggestionsHeader.isHidden = true
        suggestionsStack.isHidden = true
        suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        headerIconContainer.alpha = 1
        headerIconContainer.isHidden = false
        titleLabel.alpha = 1
        titleLabel.isHidden = false
        subtitleLabel.alpha = 1
        subtitleLabel.isHidden = false
        budgetTextInput.isHidden = false
        generateButton.alpha = 1
        generateButton.isHidden = false
        editBudgetFAB.isHidden = true
        
        contentStack.alpha = 0
        contentStack.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.contentStack.alpha = 1
        }
    }
    
    // MARK: - Actions
    
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func budgetTextDidChange() {
        // If a plan is visible, changing the budget returns to the initial state
        if !suggestionsHeader.isHidden {
            transitionToInitialState()
        }
    }
    
    /// Called when the user taps the "Generate My Plan" button.
    @objc private func didTapGenerate() {
        budgetTextInput.resignFirstResponder()
        
        let budget = Int(budgetTextInput.text ?? "0") ?? 0
        
        var config = generateButton.configuration ?? UIButton.Configuration.plain()
        config.showsActivityIndicator = true
        generateButton.configuration = config
        generateButton.isEnabled = false
        
        fetchAISuggestions(for: budget)
    }
    
    @objc private func didTapStartOver() {
        let viewController = BudgetHabitSelectorViewController(transactions: allTransactions)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    
    // MARK: - Data Logic
    
    private func loadSavedPlan() {
        DataService.loadBudgetPlan { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let response):
                    // A plan exists; load transactions before displaying it
                    self.loadTransactionsAndShowPlan(
                        plan: response.budgetPlan,
                        totalBudget: response.totalBudget
                    )
                    
                case .failure:
                    // No saved plan; load transactions for creating a new plan
                    self.loadTransactionsForNewPlan()
                }
            }
        }
    }
    
    private func loadTransactionsAndShowPlan(plan: [String: BudgetPlanItem], totalBudget: Int) {
        activityIndicator.startAnimating()
        
        loadTransactionsForReallocation { [weak self] success in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            
            if success {
                self.transitionToPlanState(plan: plan, totalBudget: totalBudget)
            } else {
                // Failed to load transactions; return to the initial state
                self.transitionToInitialState()
                // TODO: Present a user-facing error message.
            }
        }
    }
    
    private func loadTransactionsForNewPlan() {
        activityIndicator.startAnimating()
        
        loadTransactionsForReallocation { [weak self] success in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            
            if success {
                self.transitionToInitialState()
            } else {
                // Failed to load transactions; return to the previous screen
                // TODO: Present a user-facing error message.
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func transitionToPlanState(plan: [String: BudgetPlanItem], totalBudget: Int) {
        activityIndicator.stopAnimating()
        
        // Hide initial views
        headerIconContainer.isHidden = true
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        budgetTextInput.isHidden = true
        generateButton.isHidden = true
        editBudgetFAB.isHidden = false
        
        // Update data
        currentPlan = plan
        currentPlanTotalBudget = totalBudget
        
        // Clear any existing suggestion cards
        suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let sortedPlan = plan
            .filter { $0.value.amount > 0 }
            .sorted {
                if $0.key.lowercased() == "buffer" { return false }
                if $1.key.lowercased() == "buffer" { return true }
                return $0.key < $1.key
            }
        
        // Build suggestion cards
        for (merchantName, item) in sortedPlan {
            let card = SuggestionCardView()
            card.configure(name: merchantName, item: item)
            
            card.onStepperChanged = { [weak self] newVisitCount in
                self?.reallocateBudgetsOnDevice(from: card, newVisits: newVisitCount)
            }
            
            suggestionsStack.addArrangedSubview(card)
            
            if merchantName.lowercased() == "buffer" {
                card.hideStepperControls()
            }
        }
        
        suggestionsHeader.isHidden = false
        suggestionsStack.isHidden = false
        contentStack.alpha = 0
        contentStack.isHidden = false
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut) {
            self.contentStack.alpha = 1
        }
    }
    
    /// Performs on-device budget reallocation without calling the network.
    /// The buffer category is adjusted to keep the total within the selected budget.
    private func reallocateBudgetsOnDevice(from changedCard: SuggestionCardView, newVisits: Int) {
        
        // Name of the merchant that changed
        guard let lockedMerchantName = changedCard.titleLabel.text else { return }
        
        // Locate the buffer card
        guard let bufferCard = suggestionsStack.arrangedSubviews.first(where: {
            ($0 as? SuggestionCardView)?.titleLabel.text?.lowercased() == "buffer"
        }) as? SuggestionCardView else {
            print("Error: Buffer card not found.")
            return
        }
        
        // Change in cost for the edited merchant
        let costPerVisit = changedCard.costPerVisit
        let newLockedValue = Int(round(costPerVisit * Double(newVisits)))
        let oldLockedValue = currentPlan[lockedMerchantName]?.amount ?? newLockedValue
        let delta = newLockedValue - oldLockedValue
        
        // Current buffer value
        let oldBufferValue = currentPlan["Buffer"]?.amount ?? 0
        
        // Prevent buffer from becoming negative
        if delta > 0 && delta > oldBufferValue {
            print("Error: Insufficient funds in buffer.")
            
            changedCard.jiggle()
            
            // Restore previous UI values for this merchant
            let oldVisits = currentPlan[lockedMerchantName]?.visits ?? 0
            changedCard.updateAmounts(amount: oldLockedValue, visits: oldVisits)
            
            return
        }
        
        let newBufferValue = oldBufferValue - delta
        
        // Update the buffer card UI
        bufferCard.updateAmounts(
            amount: newBufferValue,
            visits: 0
        )
        
        // Update the in-memory plan
        var finalTotal = 0
        for (merchantName, details) in currentPlan {
            var newAmount = details.amount
            var updatedVisits = details.visits
            
            if merchantName == lockedMerchantName {
                newAmount = newLockedValue
                updatedVisits = newVisits
            } else if merchantName == "Buffer" {
                newAmount = newBufferValue
                updatedVisits = 0
            }
            
            let newPercent = currentPlanTotalBudget > 0
            ? Int((Double(newAmount) / Double(currentPlanTotalBudget)) * 100)
            : 0
            
            currentPlan[merchantName] = BudgetPlanItem(
                amount: newAmount,
                percent: newPercent,
                subtitle: details.subtitle,
                category: details.category,
                costPerVisit: details.costPerVisit,
                visits: updatedVisits
            )
            finalTotal += newAmount
        }
        
        // Correct for any rounding differences so the total matches the budget
        let budgetDifference = currentPlanTotalBudget - finalTotal
        if budgetDifference != 0, let bufferStruct = currentPlan["Buffer"] {
            let correctedBufferAmount = newBufferValue + budgetDifference
            let correctedBufferPercent = currentPlanTotalBudget > 0
            ? Int((Double(correctedBufferAmount) / Double(currentPlanTotalBudget)) * 100)
            : 0
            
            currentPlan["Buffer"] = BudgetPlanItem(
                amount: correctedBufferAmount,
                percent: correctedBufferPercent,
                subtitle: bufferStruct.subtitle,
                category: bufferStruct.category,
                costPerVisit: bufferStruct.costPerVisit,
                visits: 0
            )
            
            bufferCard.updateAmounts(
                amount: correctedBufferAmount,
                visits: 0
            )
        }
        
        // Persist the updated plan
        saveCurrentPlan()
    }
    
    /// Saves the current budget plan to the backend with a debounce.
    private func saveCurrentPlan() {
        // Cancel any pending save
        debounceTimer?.invalidate()
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            print("Saving budget plan to backend.")
            DataService.saveBudgetPlan(
                plan: self.currentPlan,
                totalBudget: self.currentPlanTotalBudget
            ) { success in
                if success {
                    print("Budget plan saved successfully.")
                } else {
                    print("Error: Failed to save budget plan.")
                }
            }
        }
    }
    
    /// Calls the AI service to fetch a suggested budget plan.
    private func fetchAISuggestions(for budget: Int) {
        DataService.fetchAISuggestion(
            transactions: allTransactions,
            budget: budget,
            selectedMerchants: selectedMerchants
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                var config = self.generateButton.configuration ?? UIButton.Configuration.plain()
                config.showsActivityIndicator = false
                self.generateButton.configuration = config
                self.generateButton.isEnabled = true
                
                switch result {
                case .success(let suggestionData):
                    self.transitionToPlanState(plan: suggestionData, totalBudget: budget)
                    self.saveCurrentPlan()
                    self.cleanNavigationStack()
                    
                case .failure(let error):
                    print("Error: AI suggestion request failed with error: \(error.localizedDescription)")
                    self.transitionToInitialState()
                    // TODO: Present a user-facing error message.
                }
            }
        }
    }
    
    /// Resets the navigation stack so the back button returns directly to the home screen.
    private func cleanNavigationStack() {
        guard let navController = navigationController else {
            print("Error: Cannot clean navigation stack because navigation controller is nil.")
            return
        }
        
        guard let rootViewController = navController.viewControllers.first else {
            print("Error: Cannot clean navigation stack because root view controller is missing.")
            return
        }
        
        let newStack = [rootViewController, self]
        navController.setViewControllers(newStack, animated: false)
    }
    
    
    /// Loads recent transactions so they are available for reallocation.
    private func loadTransactionsForReallocation(completion: @escaping (Bool) -> Void) {
        // Use existing transactions if already loaded
        if !allTransactions.isEmpty {
            print("Transactions already loaded.")
            completion(true)
            return
        }
        
        print("Loading transactions in background.")
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -42, to: endDate) else {
            completion(false)
            return
        }
        
        let startDateString = iso8601(startDate)
        let endDateString = iso8601(endDate)
        
        DataService.loadTransactions(startDate: startDateString, endDate: endDateString) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transactions):
                    self?.allTransactions = transactions
                    print("Background transactions loaded successfully.")
                    completion(true)
                case .failure(let error):
                    print("Error: Failed to load transactions with error: \(error)")
                    completion(false)
                }
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
}
fileprivate extension UITextField {
    func addDoneToolbar() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(resignFirstResponder))
        
        toolbar.items = [flexSpace, doneButton]
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
}
