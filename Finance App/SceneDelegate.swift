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
    
    private static var isSwitchingRoot = false
    
    // Reuse one place to build the main tab bar
    private static func makeMainTabBar() -> UITabBarController {
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
        return tabBar
    }

    // Decide if we’re already showing the same logical root
    private static func isSameRoot(current: UIViewController?, new: UIViewController) -> Bool {
        switch (current, new) {
        case (is MainTabBarController, is MainTabBarController):
            return true
        case (is OnboardingViewController, is OnboardingViewController):
            return true
        case (let cur as UINavigationController, let nxt as UINavigationController):
            let curRoot = cur.viewControllers.first
            let nxtRoot = nxt.viewControllers.first
            return (curRoot is LoginViewController) && (nxtRoot is LoginViewController)
        default:
            return false
        }
    }

    // One safe way to perform the swap
    private static func safelySetRoot(_ newRoot: UIViewController, on window: UIWindow) {
        onMain {
            // no-op if the same root type is already active
            if isSameRoot(current: window.rootViewController, new: newRoot) { return }
            // avoid overlapping transitions
            if isSwitchingRoot { return }
            isSwitchingRoot = true

            // clean up any presented VC / keyboard
            window.rootViewController?.dismiss(animated: false)
            window.endEditing(true)

            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = newRoot
            }, completion: { _ in
                isSwitchingRoot = false
            })
        }
    }


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 1) Create your window
        // 1) Create your window
            let win = UIWindow(windowScene: windowScene)
            window = win

            // 2) Apply the theme
            ThemeManager.shared.applyInitialTheme(for: win)
            
            // 3) Show the correct initial screen
            SceneDelegate.switchToLogin()

            // 4) Make the window visible
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

        let tabBar = makeMainTabBar()
        safelySetRoot(tabBar, on: window)
    }


    static func switchToLogin() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windowScene.delegate as? SceneDelegate,
              let window = delegate.window else { return }

        let rootVC: UIViewController

        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") == false {
            // Onboarding
            rootVC = OnboardingViewController()
        } else if AuthService.isSignedIn() {
            // Already signed in -> main app
            rootVC = makeMainTabBar()
        } else {
            // Login
            let loginVC = LoginViewController()
            rootVC = UINavigationController(rootViewController: loginVC)
        }

        safelySetRoot(rootVC, on: window)
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
        
        if UserDefaults.standard.bool(forKey: "shouldSwitchToLoginAfterSettings") {
            UserDefaults.standard.set(false, forKey: "shouldSwitchToLoginAfterSettings")
            SceneDelegate.switchToLogin()
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                NotificationService.shared.refreshDailySummaryNotification()
            }
        }
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

