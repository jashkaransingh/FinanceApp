//
//  HistoryViewController.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class HistoryViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
      navigationItem.title = "History"
      
      navigationItem.rightBarButtonItem = UIBarButtonItem(
              title: "Sign Out",
              style: .plain,
              target: self,
              action: #selector(signOutTapped)
          )
      
  }
    @objc private func signOutTapped() {
        let alert = UIAlertController(title: "Sign Out?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            AuthService.signOut()
            SceneDelegate.switchToLogin()
        })
        present(alert, animated: true)

    }

}
