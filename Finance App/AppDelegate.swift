//
//  AppDelegate.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import FirebaseCore
import UserNotifications
import LinkKit
import GoogleSignIn
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        _ = NetworkMonitor.shared
        UINavigationBar.appearance().prefersLargeTitles = true
        FirebaseApp.configure()
        
        guard let firebaseApp = FirebaseApp.app(), let clientID = firebaseApp.options.clientID else {
            fatalError("Could not configure Firebase/Google Sign-In: clientID is missing.")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        // Register default settings for notifications.
        registerDefaultNotificationSettings()
        
        // Hook up UNUserNotificationCenter delegate.
        UNUserNotificationCenter.current().delegate = self
        
        performFirstInstallSecurityCleanup()
        
        return true
    }
    
    // MARK: - Default Settings
    
    /// Sets the default values for notification toggles to ON the first time the app is run.
    private func registerDefaultNotificationSettings() {
        var defaults: [String: Any] = [:]
        // We can now loop through our settings without creating dummy notifications!
        for setting in NotificationSetting.allCases {
            defaults[setting.key] = true
        }
        UserDefaults.standard.register(defaults: defaults)
    }
    
    private func performFirstInstallSecurityCleanup() {
        let flag = "didRunInitialSecurityCleanup_v1"

        // Only once on a clean install (UserDefaults is empty on reinstall)
        if !UserDefaults.standard.bool(forKey: flag) {
            // 1) Sign out of Firebase (clears Firebase tokens from keychain)
            do { try Auth.auth().signOut() } catch { print("SignOut error:", error) }

            // 2) Sign out of Google if used (prevents silent restore)
            GIDSignIn.sharedInstance.signOut()

            // 3) (Optional) Clear any of your own keychain items
            // If your KeychainHelper has a wipe/reset method, call it here.
            // e.g., KeychainHelper.shared.resetAll()

            // 4) Ensure onboarding starts fresh (usually already false on clean install)
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

            // 5) Mark done so we don't log people out after normal updates
            UserDefaults.standard.set(true, forKey: flag)
        }
    }

    
    // MARK: - Standard Delegate Methods
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when the app is in the foreground.
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
}


