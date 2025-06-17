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

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {



    func application(
          _ application: UIApplication,
          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
          // You can configure global appearance here:
          UINavigationBar.appearance().prefersLargeTitles = true
            FirebaseApp.configure()
            
            // 3) Hook up UNUserNotificationCenter
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            // 4) Request permission & schedule your 8:30 AM alert
            NotificationService.shared.requestAuthorization { granted in
                guard granted else { return }
                // Schedule one notification for the next 8:30 AM
                NotificationService.shared.scheduleTomorrowMorning()
            }
            
          return true
        }
    
    
    func userNotificationCenter(
          _ center: UNUserNotificationCenter,
          willPresent notification: UNNotification,
          withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([.banner, .sound])
        }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

