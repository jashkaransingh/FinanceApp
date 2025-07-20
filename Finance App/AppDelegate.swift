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

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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
        
        // Request permission & schedule the initial daily summary.
        NotificationService.shared.requestAuthorization { granted in
            guard granted else { return }
            NotificationService.shared.refreshDailySummaryNotification()
        }
        
        return true
    }
    
    // MARK: - Default Settings
    
    /// Sets the default values for notification toggles to ON the first time the app is run.
    private func registerDefaultNotificationSettings() {
        // FIX: Create placeholder instances of the enum to access their properties.
        // We provide dummy data for the context just to create the instance.
        let defaults: [String: Any] = [
            NotificationType.dailySummary(context: .init(spentYesterday: 0, spentDayBefore: 0)).userDefaultsKey!: true,
            NotificationType.weeklySummary.userDefaultsKey!: true,
            NotificationType.weekendAlert.userDefaultsKey!: true,
            // For budget alerts, we use the same key, so we only need one of the cases.
            NotificationType.budgetNearLimit(context: .init(category: "", percent: nil)).userDefaultsKey!: true
        ]
        
        UserDefaults.standard.register(defaults: defaults)
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


