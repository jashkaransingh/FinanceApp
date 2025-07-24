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

// MARK: - NotificationType Enum (Refactored)
enum NotificationType {
    case dailySummary(context: DailySummaryContext)
    case weeklySummary
    case weekendAlert
    case budgetNearLimit(context: BudgetContext)
    case budgetFinished(context: BudgetContext)

    var identifier: String {
        switch self {
        case .dailySummary: return "dailySummaryNotification"
        case .weeklySummary: return "weeklySummaryNotification"
        case .weekendAlert: return "weekendAlert"
        case .budgetNearLimit: return "budgetNearLimitNotification"
        case .budgetFinished: return "budgetFinishedNotification"
        }
    }
    
    var userDefaultsKey: String? {
        switch self {
        case .dailySummary: return "dailySummaryEnabled"
        case .weeklySummary: return "weeklySummaryEnabled"
        case .weekendAlert: return "weekendAlertsEnabled"
        case .budgetNearLimit, .budgetFinished: return "budgetAlertsEnabled"
        }
    }
    
    var timeDefaultsKey: String? {
        switch self {
        case .dailySummary: return "dailySummaryTime"
        case .weeklySummary: return "weeklySummaryTime"
        default: return nil
        }
    }

    var content: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        switch self {
        case .dailySummary(let context):
            let fmt = NumberFormatter(); fmt.numberStyle = .currency
            let spentYStr = fmt.string(from: context.spentYesterday as NSNumber) ?? "$0.00"
            content.title = "Yesterday you spent \(spentYStr)"
            content.body = "Tap to see your full daily spending breakdown."
            
        case .weeklySummary:
            content.title = "Your Weekly Spending Summary"
            content.body = "Tap to see how you did with your budget this past week."
            
        case .weekendAlert:
            content.title = "It's the Weekend! ☀️"
            content.body = "Enjoy yourself, and remember to keep an eye on your spending goals!"

        case .budgetNearLimit(let context):
            let percent = context.percent ?? 90
            content.title = "Careful with your spending!"
            content.body = "You've already spent \(percent)% of your budget for \(context.category) this month."

        case .budgetFinished(let context):
            content.title = "Budget Reached! 🎉"
            content.body = "You've finished your budget for \(context.category). Any more spending will be over budget."
        }
        return content
    }
}

// MARK: - NotificationService
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private init() {}
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }
    
    func scheduleNotification(for type: NotificationType, at components: DateComponents? = nil) {
        if let key = type.userDefaultsKey, !UserDefaults.standard.bool(forKey: key) { return }
        let content = type.content
        
        switch type {
        case .dailySummary:
            let trigger = UNCalendarNotificationTrigger(dateMatching: components ?? getStoredTime(for: type), repeats: false)
            addRequest(identifier: type.identifier, content: content, trigger: trigger)
        case .weeklySummary:
            var time = components ?? getStoredTime(for: type); time.weekday = 2 // Monday
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            addRequest(identifier: type.identifier, content: content, trigger: trigger)
        case .weekendAlert:
            for weekday in [1, 7] {
                var comps = DateComponents(); comps.weekday = weekday; comps.hour = 9; comps.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let identifier = "\(type.identifier)_\(weekday)"
                addRequest(identifier: identifier, content: content, trigger: trigger)
            }
        case .budgetNearLimit(let context), .budgetFinished(let context):
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let identifier = "\(type.identifier)_\(context.category)" // Predictable ID
            addRequest(identifier: identifier, content: content, trigger: trigger)
        }
    }
    
    func cancelNotification(for type: NotificationType) { /* ... Your cancellation logic ... */ }
    
    func saveTime(for type: NotificationType, components: DateComponents) {
        guard let key = type.timeDefaultsKey else { return }
        UserDefaults.standard.set(try? JSONEncoder().encode(components), forKey: key)
    }
    
    func getStoredTime(for type: NotificationType) -> DateComponents {
        guard let key = type.timeDefaultsKey,
              let data = UserDefaults.standard.data(forKey: key),
              let components = try? JSONDecoder().decode(DateComponents.self, from: data) else {
            return DateComponents(hour: 8, minute: 30)
        }
        return components
    }
    
    func refreshDailySummaryNotification(at components: DateComponents? = nil) {
        // In a real app, you would fetch real data here.
        let context = DailySummaryContext(spentYesterday: 75.20, spentDayBefore: 55.10)
        let notificationType = NotificationType.dailySummary(context: context)
        self.scheduleNotification(for: notificationType, at: components)
    }

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

extension Notification.Name {
  static let bankLinkChanged = Notification.Name("bankLinkChanged")
}



