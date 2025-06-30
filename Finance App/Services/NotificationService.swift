//
//  NotificationService.swift
//  Finance App
//
//  Created by Jas  on 6/9/25.
//

import Foundation
import UserNotifications


/// Responsible for asking permission, computing your daily spend delta,
/// and scheduling a local notification every morning at 8:30.
final class NotificationService {
    
  
  static let shared = NotificationService()
  private init() {}

  private let center = UNUserNotificationCenter.current()
    
    private static let isoDateFormatter: DateFormatter = {
      let f = DateFormatter()
      f.dateFormat = "yyyy-MM-dd"
      f.locale = Locale(identifier: "en_US_POSIX")
      return f
    }()

  
  /// Call once, e.g. in AppDelegate.didFinishLaunching, to request permission
  func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      completion?(granted)
    }
  }

  /// Schedules *one* notification for the next 8:30 AM with up-to-date content.
  /// Call this each time the app launches (or after user opens the app), so that
  /// you always have a fresh notification queued.
    func scheduleTomorrowMorning() {
            let calendar = Calendar.current
            let today = Date()
            guard
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)
            else { return }
            
            // Use a DispatchGroup to wait for both network calls to complete.
            let group = DispatchGroup()
            
            var spentYesterday: Double = 0
            var spentDayBefore: Double = 0
            
            group.enter()
            fetchTotalSpending(on: yesterday) { total in
                spentYesterday = total
                group.leave()
            }
            
            group.enter()
            fetchTotalSpending(on: twoDaysAgo) { total in
                spentDayBefore = total
                group.leave()
            }
            
            // This block executes only after both fetch calls have finished.
            group.notify(queue: .main) { [weak self] in
                self?.buildAndScheduleNotification(spentYesterday: spentYesterday, spentDayBefore: spentDayBefore)
            }
        }

  // MARK: - Helpers

    /// Wraps our new secure DataService to sum transactions on a single date.
        private func fetchTotalSpending(on date: Date, completion: @escaping (Double) -> Void) {
            let dayStr = Self.isoDateFormatter.string(from: date)
            
            // Call the new, secure function. No token needed!
            DataService.loadTransactions(startDate: dayStr, endDate: dayStr) { result in
                switch result {
                case .success(let transactions):
                    let total = transactions.reduce(0.0) { $0 + $1.amount }
                    completion(total)
                case .failure(let error):
                    print("🚨 Notif Service failed to fetch transactions for \(dayStr):", error)
                    completion(0) // Return 0 on failure
                }
            }
        }
    
    /// Builds and schedules the notification content.
        private func buildAndScheduleNotification(spentYesterday: Double, spentDayBefore: Double) {
            let delta = spentDayBefore - spentYesterday
            let pct = (spentDayBefore > 0) ? (delta / spentDayBefore * 100) : 0
            
            let fmt = NumberFormatter()
            fmt.numberStyle = .currency
            
            let spentYStr = fmt.string(from: spentYesterday as NSNumber) ?? "$0.00"
            let deltaStr = fmt.string(from: abs(delta) as NSNumber) ?? "$0.00"
            let changeWord = delta >= 0 ? "less" : "more"
            
            let content = UNMutableNotificationContent()
            content.title = "Yesterday you spent \(spentYStr)"
            content.body = "That's \(deltaStr) (\(String(format: "%.0f%%", abs(pct)))) \(changeWord) than the day before."
            content.sound = .default
            
            // Build trigger for next 8:30 AM
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = 8
            comps.minute = 30
            if let fireDate = Calendar.current.date(from: comps), fireDate <= Date() {
                 comps.day = (comps.day ?? 1) + 1
            }
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = "dailySpendingNotification"
            center.removePendingNotificationRequests(withIdentifiers: [id])
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req) { error in
                if let err = error {
                    print("🚨 Failed to schedule notification:", err)
                } else {
                    print("✅ Daily spending notification scheduled.")
                }
            }
        }
    /// In NotificationService
    func scheduleTestNotification(after seconds: TimeInterval = 5) {
      let content = UNMutableNotificationContent()
      content.title = "🛠️ Test Notification"
      content.body  = "This is your spending summary test payload."
      content.sound = .default

      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds,
                                                      repeats: false)
      let req = UNNotificationRequest(identifier: "testNotification",
                                      content: content,
                                      trigger: trigger)

      center.add(req) { error in
        if let e = error { print("Test-notif failed:", e) }
      }
    }

}

extension NotificationService {
  
  /// Schedules a real “yesterday vs. day-before” spending notification
  /// after `seconds`—perfect for UI testing.
  func scheduleSummaryNotification(after seconds: TimeInterval = 10) {
    let calendar = Calendar.current
    let today = Date()
    guard
      let yesterday   = calendar.date(byAdding: .day, value: -1, to: today),
      let twoDaysAgo  = calendar.date(byAdding: .day, value: -2, to: today)
    else { return }

    // 1) Fetch the two totals
    fetchTotalSpending(on: yesterday) { [weak self] spentYesterday in
      self?.fetchTotalSpending(on: twoDaysAgo) { spentDayBefore in

        // 2) Compute delta & percent
        let delta = spentDayBefore - spentYesterday
        let pct   = (spentDayBefore > 0)
          ? delta / spentDayBefore * 100
          : 0

        // 3) Format strings
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency

        let yStr   = fmt.string(from: spentYesterday  as NSNumber) ?? "$0.00"
        let dStr   = fmt.string(from: delta           as NSNumber) ?? "$0.00"
        let pStr   = String(format: "%.0f%%", pct)

        // 4) Build content
        let content = UNMutableNotificationContent()
        content.title = "Yesterday you spent \(yStr)"
        content.body  = "That's \(dStr) (\(pStr)) less than the day before."
        content.sound = .default

        // 5) Schedule in `seconds`
        let trigger = UNTimeIntervalNotificationTrigger(
          timeInterval: seconds,
          repeats: false
        )
        let req = UNNotificationRequest(
          identifier: "testSummaryNotification",
          content: content,
          trigger: trigger
        )
          self?.center.add(req) { err in
            if let e = err { print("couldn’t schedule test-summary:", e) }
          }
      }
    }
  }
}

