//
//  BudgetHabitSelectorViewController.swift
//  Finance App
//
//  Created by Jas  on 11/27/25.
//

import UIKit

/// First screen in the Budget AI flow.
/// Displays frequent merchants for the user to select.
final class BudgetHabitSelectorViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "What are your spending habits?"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Select your recurring expenses to build a plan."
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(HabitCell.self, forCellReuseIdentifier: HabitCell.reuseID)
        tv.rowHeight = 70
        tv.separatorStyle = .none
        tv.allowsMultipleSelection = true
        tv.backgroundColor = .clear
        return tv
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .label
        button.tintColor = .systemBackground
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Data Properties
    
    private var allTransactions: [Transaction] = []
    private var allHabits: [FrequentMerchant] = []
    private var selectedHabits: Set<FrequentMerchant.ID> = []
    private var savedPlan: [String: BudgetPlanItem]?
    private var savedBudget: Int = 200
    
    // MARK: - Lifecycle
    
    /// Initializes the selector with transactions from the previous screen.
    init(transactions: [Transaction]) {
        self.allTransactions = transactions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupLayout()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchHabits()
    }
    
    // MARK: - Setup
    
    private func setupNavBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Select Habits"
    }
    
    private func setupLayout() {
        view.addSubview(headerLabel)
        view.addSubview(subHeaderLabel)
        view.addSubview(tableView)
        view.addSubview(nextButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            subHeaderLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            subHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: subHeaderLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            nextButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data
    
    private func fetchHabits() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        nextButton.isHidden = true
        
        let group = DispatchGroup()
        var fetchError: NetworkError?
        
        // Task 1: Fetch frequent merchants
        group.enter()
        DataService.fetchFrequentMerchants(transactions: allTransactions) { [weak self] result in
            switch result {
            case .success(let merchants):
                self?.allHabits = merchants
            case .failure(let error):
                print("Error: Failed to fetch frequent merchants: \(error)")
                fetchError = error
            }
            group.leave()
        }
        
        // Task 2: Load saved budget plan
        group.enter()
        DataService.loadBudgetPlan { [weak self] result in
            switch result {
            case .success(let response):
                print("Loaded saved plan; preselecting habits.")
                self?.savedPlan = response.budgetPlan
                self?.savedBudget = response.totalBudget
            case .failure:
                print("No saved plan found. Starting a new plan.")
                self?.savedPlan = nil
                // Default savedBudget of 200 is preserved.
            }
            group.leave()
        }
        
        // Runs after both tasks are complete
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            self.tableView.isHidden = false
            self.nextButton.isHidden = false
            
            if fetchError != nil {
                self.subHeaderLabel.text = "Could not load habits."
                self.subHeaderLabel.textColor = .systemRed
                return
            }
            
            if let savedPlan = self.savedPlan {
                // Pre-select merchants from the saved plan
                let savedMerchantNames = Set(savedPlan.keys)
                let selected = self.allHabits.filter { savedMerchantNames.contains($0.name) }
                self.selectedHabits = Set(selected.map { $0.id })
            } else {
                // New user: pre-select the top three habits
                let top3 = self.allHabits.prefix(3).map { $0.id }
                self.selectedHabits = Set(top3)
            }
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func didTapNext() {
        // Names of the selected merchants
        let selectedMerchantNames = allHabits
            .filter { selectedHabits.contains($0.id) }
            .map { $0.name }
        
        // Initialize the next screen
        let budgetVC = BudgetAssistantViewController(
            transactions: allTransactions,
            selectedMerchants: selectedMerchantNames
        )
        
        // Pass the saved budget amount to the next screen.
        // For new users, this is the default of 200.
        // For returning users, this is the saved budget.
        budgetVC.initialBudgetAmount = savedBudget
        
        navigationController?.pushViewController(budgetVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension BudgetHabitSelectorViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allHabits.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HabitCell.reuseID,
            for: indexPath
        ) as? HabitCell else {
            return UITableViewCell()
        }
        
        let habit = allHabits[indexPath.row]
        let isSelected = selectedHabits.contains(habit.id)
        
        cell.configure(with: habit, isSelected: isSelected)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        cell.onToggle = { [weak self] isSelected in
            if isSelected {
                self?.selectedHabits.insert(habit.id)
            } else {
                self?.selectedHabits.remove(habit.id)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Support tapping the entire row to toggle selection
        guard let cell = tableView.cellForRow(at: indexPath) as? HabitCell else { return }
        cell.didTapCheckbox()
    }
}
