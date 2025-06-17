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
    // 1) Compute “yesterday” and “day before yesterday”
    let calendar = Calendar.current
    let today     = Date()
    guard
      let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
      let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)
    else { return }

    // 2) Fetch spending for those two dates
    fetchTotalSpending(on: yesterday) { [weak self] spentYesterday in
      self?.fetchTotalSpending(on: twoDaysAgo) { spentDayBefore in
        // 3) Build notification content
        let delta    = spentDayBefore - spentYesterday
        let pct      = (spentDayBefore > 0)
          ? delta / spentDayBefore * 100
          : 0

        let fmt = NumberFormatter()
        fmt.numberStyle = .currency

        let spentYStr  = fmt.string(from: spentYesterday as NSNumber)  ?? "$0.00"
        let deltaStr   = fmt.string(from: delta as NSNumber)         ?? "$0.00"
        let pctStr     = String(format: "%.0f%%", pct)

        let content = UNMutableNotificationContent()
        content.title = "Yesterday you spent \(spentYStr)"
        content.body  = "That's \(deltaStr) (\(pctStr)) less than the day before."
        content.sound = .default

        // 4) Build a trigger for next 8:30 AM
        var comps = calendar.dateComponents([.year, .month, .day], from: today)
        comps.hour   = 8
        comps.minute = 30
        // If 8:30 has already passed today, schedule for tomorrow:
          if let fireDate = calendar.date(from: comps), fireDate <= today {
            comps.day! += 1
          }
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        // 5) Remove any existing pending request and enqueue this one
        let id = "dailySpendingNotification"
        self?.center.removePendingNotificationRequests(withIdentifiers: [id])
        let req = UNNotificationRequest(identifier: id,
                                        content: content,
                                        trigger: trigger)
        self?.center.add(req) { error in
          if let err = error {
            print("🚨 Failed to schedule notification:", err)
          }
        }
      }
    }
  }

  // MARK: - Helpers

  /// Wraps your DataService.loadTransactionsBetween to sum all
  /// transactions on a single date.
  private func fetchTotalSpending(on date: Date,
                                  completion: @escaping (Double) -> Void)
  {
      let dayStr = Self.isoDateFormatter.string(from: date)

    // since your backend takes start/end ISO dates, pass the same
    DataService.loadTransactions(
      accessToken: UserDefaults.standard.string(forKey: "plaidAccessToken") ?? "",
      startDate: dayStr,
      endDate:   dayStr
    ) { txs in
      let total = txs.reduce(0.0) { $0 + $1.amount }
      completion(total)
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

