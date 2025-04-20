//
//  DataService.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import Foundation
class DataService {
  static func loadSummaries() -> [AccountSummary] {
    return [
      AccountSummary(
        periodTitle: "Spent Today",
        amount: 64.30,
        percentage: -11,
        subtitle: "Yesterday $72.50",
        usesPieIcon: false
      ),
      AccountSummary(
        periodTitle: "Spent This Week",
        amount: 410.60,
        percentage: -18,
        subtitle: "Last Week $498.00",
        usesPieIcon: false
      ),
      AccountSummary(
        periodTitle: "Spent This Month",
        amount: 1025.90,
        percentage: 41,
        subtitle: "Last Month $2,045.00",
        usesPieIcon: true
      )
    ]
  }
}
