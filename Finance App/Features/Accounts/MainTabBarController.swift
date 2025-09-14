//
//  MainTabBarController.swift
//  Finance App
//
//  Created by Jas  on 6/10/25.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    // Called whenever a new tab is selected
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        HapticsManager.trigger(.selection)
    }
}

