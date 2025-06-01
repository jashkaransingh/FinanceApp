//
//  SceneDelegate.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 1) Create your window
            let win = UIWindow(windowScene: windowScene)
            window = win

            // 2) Pull the saved dark–mode flag and apply it globally
            let darkOn = UserDefaults.standard.bool(forKey: "darkModeEnabled")
            win.overrideUserInterfaceStyle = darkOn ? .dark : .light

            // 3) Now decide your root view controller
            if AuthService.isSignedIn() {
                SceneDelegate.switchToMainApp()
            } else {
                let loginVC = LoginViewController()
                let nav = UINavigationController(rootViewController: loginVC)
                win.rootViewController = nav
            }

            win.makeKeyAndVisible()
            
            window = UIWindow(windowScene: windowScene)

            if AuthService.isSignedIn() {
                SceneDelegate.switchToMainApp()
            } else {
                let loginVC = LoginViewController()
                let nav = UINavigationController(rootViewController: loginVC)
                window?.rootViewController = nav
            }

            window?.makeKeyAndVisible()
          }
    
    static func switchToMainApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windowScene.delegate as? SceneDelegate,
              let window = delegate.window else { return }

        let accountsVC = AccountsViewController()
        let nav1 = UINavigationController(rootViewController: accountsVC)
        nav1.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "creditcard.fill"), tag: 0)

        let historyVC = HistoryViewController()
        let nav2 = UINavigationController(rootViewController: historyVC)
        nav2.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "clock"), tag: 1)

        let tabBar = UITabBarController()
        tabBar.viewControllers = [nav1, nav2]
        tabBar.tabBar.tintColor = .label
        tabBar.tabBar.unselectedItemTintColor = .secondaryLabel

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBar
        })
    }


    static func switchToLogin() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                 let delegate = windowScene.delegate as? SceneDelegate,
                 let window = delegate.window else { return }

           let loginVC = LoginViewController()
           let nav = UINavigationController(rootViewController: loginVC)

           UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
               window.rootViewController = nav
           })
    }


    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

