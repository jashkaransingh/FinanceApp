//
//  AppDelegate.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // Centralize the UserDefaults keys used here
    private enum DefaultsKey {
        static let didRunInitialSecurityCleanup_v1 = "didRunInitialSecurityCleanup_v1"
        static let hasCompletedOnboarding          = "hasCompletedOnboarding"
    }

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        _ = NetworkMonitor.shared

        UINavigationBar.appearance().prefersLargeTitles = true
        FirebaseApp.configure()

        if let app = FirebaseApp.app(), let clientID = app.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        } else {
            #if DEBUG
            assertionFailure("Could not configure Firebase/Google Sign-In: clientID is missing.")
            #endif
            // In Release, we simply don’t enable Google sign-in.
        }

        registerDefaultNotificationSettings()
        UNUserNotificationCenter.current().delegate = self

        performFirstInstallSecurityCleanup()

        return true
    }

    // MARK: - Default Notification Settings
    private func registerDefaultNotificationSettings() {
        var defaults: [String: Any] = [:]
        for setting in NotificationSetting.allCases {
            defaults[setting.key] = true
        }
        UserDefaults.standard.register(defaults: defaults)
    }

    // MARK: - First-Install Security Cleanup

    private func performFirstInstallSecurityCleanup() {
        let flag = DefaultsKey.didRunInitialSecurityCleanup_v1
        if !UserDefaults.standard.bool(forKey: flag) {
            do { try Auth.auth().signOut() } catch {
                #if DEBUG
                print("SignOut error:", error)
                #endif
            }

            // Sign out of Google to prevent silent restore
            GIDSignIn.sharedInstance.signOut()

            // If you have a keychain wipe, call it here:
            // KeychainHelper.shared.resetAll()

            // Ensure onboarding starts fresh
            UserDefaults.standard.set(false, forKey: DefaultsKey.hasCompletedOnboarding)

            // Mark done so we don't log people out after normal updates
            UserDefaults.standard.set(true, forKey: flag)
        }
    }

    // MARK: - URL Handling

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when the app is in the foreground.
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
}



