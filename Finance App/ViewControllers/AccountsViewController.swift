//
//  AccountsViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class AccountsViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private var summaries: [AccountSummary] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = "My Accounts"

    summaries = DataService.loadSummaries()
    setupScrollStack()
    populateCards()
    setupFloatingButton()
  }

  private func setupScrollStack() {
    view.addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])

    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    stackView.isLayoutMarginsRelativeArrangement = true

    scrollView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
    ])
  }

  private func populateCards() {
    summaries.forEach { model in
      let card = AccountCardView()
      card.configure(with: model)
      card.translatesAutoresizingMaskIntoConstraints = false
      card.heightAnchor.constraint(equalToConstant: 140).isActive = true

      let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
      card.addGestureRecognizer(tap)

      stackView.addArrangedSubview(card)
    }
  }

  @objc private func cardTapped(_ recognizer: UITapGestureRecognizer) {
    let detailVC = AccountDetailViewController()
    // you can pass data: detailVC.model = …
    navigationController?.pushViewController(detailVC, animated: true)
  }

  private func setupFloatingButton() {
    let fab = FloatingActionButton()
    view.addSubview(fab)
    NSLayoutConstraint.activate([
      fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
    ])
    fab.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
  }

  @objc private func fabTapped() {
    // present your “New Transaction” flow here
  }
}
