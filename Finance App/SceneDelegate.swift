//
//  SceneDelegate.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import LinkKit
import LocalAuthentication

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

        ThemeManager.shared.applyInitialTheme(for: win)

            // 3) Now decide your root view controller
            if AuthService.isSignedIn() {
                SceneDelegate.switchToMainApp()
            } else {
                let loginVC = LoginViewController()
                let nav = UINavigationController(rootViewController: loginVC)
                win.rootViewController = nav
            }

            win.makeKeyAndVisible()
          }
//    func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
//        PlaidService.shared.linkHandler?.open(
//          presentUsing: .viewController(UIApplication.shared.topMostViewController()!)
//        )
//    }
    
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

        let tabBar = MainTabBarController()
        tabBar.viewControllers = [nav1, nav2]
        tabBar.tabBar.tintColor = .label
        tabBar.tabBar.unselectedItemTintColor = .secondaryLabel

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBar
        })
    }

    static func switchToLogin() {
            // Ensure this UI change happens on the main thread.
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let delegate = windowScene.delegate as? SceneDelegate,
                      let window = delegate.window else {
                    print("Error: Could not access window to switch to login.")
                    return
                }

                let loginVC = LoginViewController()
                let nav = UINavigationController(rootViewController: loginVC)

                // Add a smooth transition
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = nav
                })
            }
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
        // Check if App Lock is enabled
        guard UserDefaults.standard.bool(forKey: "isAppLockEnabled") else { return }
        
        
        
        // Find the current top-most view controller to present from
        guard let rootVC = window?.rootViewController else { return }
        
        // Prevent presenting if a lock screen (or any other modal) is already up
        if rootVC.presentedViewController != nil {
            return
        }
        
        // Present the lock screen
        let lockVC = LockViewController()
        lockVC.modalPresentationStyle = .overFullScreen
        rootVC.present(lockVC, animated: false) 
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
extension UIApplication {
    func topMostViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController,
           let selected = tab.selectedViewController {
            return topMostViewController(base: selected)
        }

        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }

        return base
    }
}

