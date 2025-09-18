//
//  NotificationService.swift
//  Finance App
//
//  Created by Jas  on 6/9/25.
//

import Foundation
import UserNotifications

// MARK: - Notification Context Models
struct DailySummaryContext {
    let spentYesterday: Double
    let spentDayBefore: Double
}

struct BudgetContext {
    let category: String
    let percent: Int?
}

// MARK: - Settings
enum NotificationSetting: String, CaseIterable {
    case dailySummary
    case weeklySummary
    case weekendAlerts
    case budgetAlerts
    
    var key: String {
        return self.rawValue + "Enabled"
    }
}

enum NotificationType {
    case dailySummary(context: DailySummaryContext)
    case weeklySummary
    case weekendAlert
    case budgetNearLimit(context: BudgetContext)
    case budgetFinished(context: BudgetContext)
    
    var identifier: String {
        switch self {
        case .dailySummary:          return "dailySummaryNotification"
        case .weeklySummary:         return "weeklySummaryNotification"
        case .weekendAlert:          return "weekendAlert"
        case .budgetNearLimit:       return "budgetNearLimitNotification"
        case .budgetFinished:        return "budgetFinishedNotification"
        }
    }
    
    /// Which toggle controls this type (if any).
    var setting: NotificationSetting? {
        switch self {
        case .dailySummary:                return .dailySummary
        case .weeklySummary:               return .weeklySummary
        case .weekendAlert:                return .weekendAlerts
        case .budgetNearLimit, .budgetFinished:
            return .budgetAlerts
        }
    }
    
    /// Storage key for scheduled time (if applicable).
    var timeDefaultsKey: String? {
        switch self {
        case .dailySummary: return "dailySummaryTime"
        case .weeklySummary: return "weeklySummaryTime"
        default: return nil
        }
    }
    
    /// Prebuilt content for this notification.
    var content: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        switch self {
        case .dailySummary(let context):
            let fmt = NumberFormatter(); fmt.numberStyle = .currency
            let spentYStr = fmt.string(from: context.spentYesterday as NSNumber) ?? "$0.00"
            content.title = "Yesterday you spent \(spentYStr)"
            content.body  = "Tap to see your full daily spending breakdown."
            
        case .weeklySummary:
            content.title = "Your Weekly Spending Summary"
            content.body  = "Tap to see how you did with your budget this past week."
            
        case .weekendAlert:
            content.title = "It's the Weekend!!!"
            content.body  = "Enjoy yourself, and remember to keep an eye on your spending goals!"
            
        case .budgetNearLimit(let context):
            let percent = context.percent ?? 90
            content.title = "Careful with your spending!"
            content.body  = "You've already spent \(percent)% of your budget for \(context.category) this month."
            
        case .budgetFinished(let context):
            content.title = "Budget Reached!"
            content.body  = "You've finished your budget for \(context.category). Any more spending will be over budget."
        }
        return content
    }
}

// MARK: - Notification Service
final class NotificationService {
    
    static let shared = NotificationService()
    private init() {}
    
    private let center = UNUserNotificationCenter.current()
    
    // Request permission (shows system prompt)
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }
    
    /// Schedule a notification for a given type.
    /// - Parameters:
    ///   - type: Notification use-case.
    ///   - components: Optional time (hour/minute). If `nil`, a stored/default time is used when applicable.
    func scheduleNotification(for type: NotificationType, at components: DateComponents? = nil) {
        // Respect user toggle if this type is gated
        if let setting = type.setting, !UserDefaults.standard.bool(forKey: setting.key) { return }
        
        let content = type.content
        
        switch type {
        case .dailySummary:
            // One-shot or “next occurrence” depending on provided components
            let comps = components ?? getStoredTime(for: type)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            addRequest(identifier: type.identifier, content: content, trigger: trigger)
            
        case .weeklySummary:
            // Weekly on Monday at stored/provided time
            var comps = components ?? getStoredTime(for: type)
            comps.weekday = 2 // Monday
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            addRequest(identifier: type.identifier, content: content, trigger: trigger)
            
        case .weekendAlert:
            // Saturday & Sunday at 9:00
            for weekday in [1, 7] {
                var comps = DateComponents()
                comps.weekday = weekday
                comps.hour = 9
                comps.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                addRequest(identifier: "\(type.identifier)_\(weekday)", content: content, trigger: trigger)
            }
            
        case .budgetNearLimit(let context),
                .budgetFinished(let context):
            // Fire once after short delay (placeholder)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            addRequest(identifier: "\(type.identifier)_\(context.category)", content: content, trigger: trigger)
        }
    }
    
    func cancelNotification(for type: NotificationType) {
        /*cancellation logic ... */
    }
    
    func saveTime(for type: NotificationType, components: DateComponents) {
        guard let key = type.timeDefaultsKey else { return }
        UserDefaults.standard.set(try? JSONEncoder().encode(components), forKey: key)
    }
    
    // Load a stored time; if none, uses a default (08:30)
    func getStoredTime(for type: NotificationType) -> DateComponents {
        guard let key = type.timeDefaultsKey,
              let data = UserDefaults.standard.data(forKey: key),
              let components = try? JSONDecoder().decode(DateComponents.self, from: data) else {
            return DateComponents(hour: 8, minute: 30)
        }
        return components
    }
    
    /// Convenience: refresh (re-schedule) the daily summary with mock data (same as before).
    func refreshDailySummaryNotification(at components: DateComponents? = nil) {
        // In a real app, fetch real data here.
        let context = DailySummaryContext(spentYesterday: 75.20, spentDayBefore: 55.10)
        scheduleNotification(for: .dailySummary(context: context), at: components)
    }
    
    // MARK: - Internals
    
    private func addRequest(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }
}

// MARK: - Date Helper
extension Date {
    var dayBefore: Date { Calendar.current.date(byAdding: .day, value: -1, to: self)! }
    var twoDaysBefore: Date { Calendar.current.date(byAdding: .day, value: -2, to: self)! }
}

// MARK: - App Notifications (kept as-is)

extension Notification.Name {
    static let bankLinkChanged = Notification.Name("bankLinkChanged")
}



