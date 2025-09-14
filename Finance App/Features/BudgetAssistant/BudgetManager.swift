//
//  BudgetManager.swift
//  Finance App
//
//  Created by Jas  on 7/2/25.
//

import Foundation

// NOTE: These models should live in their own file, but are here for context.
struct Budget {
    var category: String
    var limit: Double
    var currentSpending: Double
}

final class BudgetManager {
    static let shared = BudgetManager()
    private init() {}
    
    func checkForBudgetNotifications(forUpdatedCategory category: String) {
        let mockBudget = getMockBudget(for: category)
        let percentSpent = Int((mockBudget.currentSpending / mockBudget.limit) * 100)

        if percentSpent >= 100 {
            // Create a type-safe context and notification type
            let context = BudgetContext(category: mockBudget.category, percent: 100)
            let notificationType = NotificationType.budgetFinished(context: context)
            NotificationService.shared.scheduleNotification(for: notificationType)
            
        } else if percentSpent >= 90 {
            // Create a type-safe context and notification type
            let context = BudgetContext(category: mockBudget.category, percent: percentSpent)
            let notificationType = NotificationType.budgetNearLimit(context: context)
            NotificationService.shared.scheduleNotification(for: notificationType)
        }
    }
    
    // This is just for the example. Delete this and use your real data.
    private func getMockBudget(for category: String) -> Budget {
        if category == "Food" {
            return Budget(category: "Food", limit: 500, currentSpending: 460)
        } else {
            return Budget(category: "Transport", limit: 100, currentSpending: 100)
        }
    }
}
