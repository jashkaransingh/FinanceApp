//
//  OnboardingViewController.swift
//  Finance App
//
//  Created by Jas  on 7/31/25.
//

import UIKit


final class OnboardingViewController: UIPageViewController {
    
    // MARK: - Properties
    
    private var pages = [UIViewController]()
    private let pageControl = UIPageControl()
    private let nextButton = InteractiveButton(type: .system)
    private var isAdvancing = false
    
    // This is where we define the content for our 3 pages
    private let allPagesData: [OnboardingPage] = [
        OnboardingPage(lottieAnimationName: "money 2", // Use the name of your JSON file
                       headline: "Your Finances, Figured Out.",
                       subtext: "See where every $dollar goes and make your money work for you."),
        OnboardingPage(lottieAnimationName: "credit card", // Use the name of your JSON file
                       headline: "All Your Accounts, One View",
                       subtext: "Securely link your accounts in seconds to track your spending and see your net worth grow."),
        OnboardingPage(lottieAnimationName: "notification", // Use the name of your JSON file
                       headline: "Get Notified, Not Annoyed.",
                       subtext: "Enable alerts for actually useful updates, like budget check-ins and spending summaries. No spam, ever.")
    ]
    
    // MARK: - Initializer
    
    override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey : Any]? = nil) {
        // We use a scroll transition style for a standard onboarding flow
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .systemBackground
        
        // Set the delegates for the page view controller
        delegate = self
        dataSource = self
        
        // Create the individual page view controllers from our data
        pages = allPagesData.map { OnboardingContentViewController(page: $0) }
        
        // Set the initial page
        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: true, completion: nil)
        }
        
        // Configure the UI elements (dots and button)
        setupControls()
    }
    func presentNotificationsDeniedUpsell() {
        let alert = UIAlertController(
            title: "Enable Alerts for Smarter Spending",
            message: "Notifications help you avoid overspending and hit your goals. You can turn them on in Settings anytime.",
            preferredStyle: .alert
        )
        let later = UIAlertAction(title: "Maybe Later", style: .cancel) { _ in
            // mark onboarding done and leave now
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            SceneDelegate.switchToLogin()
        }

        let open = UIAlertAction(title: "Open Settings", style: .default) { _ in
            // mark onboarding done, and ask SceneDelegate to switch after we return
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(true, forKey: "shouldSwitchToLoginAfterSettings")

            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }

        alert.addAction(later)
        alert.addAction(open)
        present(alert, animated: true)
    }

}

// MARK: - UIPageViewControllerDataSource

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController), currentIndex > 0 else {
            return nil // We are at the first page
        }
        return pages[currentIndex - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController), currentIndex < pages.count - 1 else {
            return nil // We are at the last page
        }
        return pages[currentIndex + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let currentVC = pageViewController.viewControllers?.first, let currentIndex = pages.firstIndex(of: currentVC) else {
            return
        }
        pageControl.currentPage = currentIndex
        updateButtonForPage(at: currentIndex)
        isAdvancing = false
        nextButton.isEnabled = true
    }
}

// MARK: - UI Setup and Actions

private extension OnboardingViewController {
    
    func setupControls() {
        // Configure Page Control (the dots)
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.currentPageIndicatorTintColor = .label
        
        // Configure Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.backgroundColor = .label
        nextButton.tintColor = .systemBackground
        nextButton.setTitleColor(.systemBackground, for: .normal)
        nextButton.setTitleColor(.tertiaryLabel, for: .disabled)
        nextButton.layer.cornerRadius = 12
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        // Add controls to the view and set constraints
        view.addSubview(pageControl)
        view.addSubview(nextButton)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            
            pageControl.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -30),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func updateButtonForPage(at index: Int) {
        if index == pages.count - 1 {
            // Last page
            nextButton.setTitle("Finish", for: .normal)
        } else {
            // Not the last page
            nextButton.setTitle("Next", for: .normal)
        }
    }
    
    @objc func nextButtonTapped() {
        guard !isAdvancing else { return }
        isAdvancing = true
        nextButton.isEnabled = false
        
        let currentIndex = pageControl.currentPage
        
        if currentIndex < pages.count - 1 {
            // Go to the next page
            let nextIndex = currentIndex + 1
            setViewControllers([pages[nextIndex]], direction: .forward, animated: true) { [weak self] _ in
                guard let self = self else { return }
                self.isAdvancing = false
                self.nextButton.isEnabled = true
            }
            pageControl.currentPage = nextIndex
            updateButtonForPage(at: nextIndex)
        } else {
            NotificationService.shared.requestAuthorization { granted in
                onMain {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    if granted {
                        // schedule only if permitted
                        NotificationService.shared.refreshDailySummaryNotification()
                        SceneDelegate.switchToLogin()
                    } else {
                        // still on onboarding: offer Settings
                        self.presentNotificationsDeniedUpsell()
                    }
                }
            }
        }
    }
}
