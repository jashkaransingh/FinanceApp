//
//  WidgetDataManager.swift
//  Finance App
//
//  Created by Jas  on 8/7/25.
//

import Foundation

/// Reads the shared JSON budget file from the App Group.
final class WidgetDataManager {
  private let appGroupID = "group.com.singh.financeapp"
  private var sharedFileURL: URL? {
    FileManager
      .default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
      .appendingPathComponent("sharedBudgetData.json")
  }

  func load() -> SharedBudgetData? {
    guard
      let url = sharedFileURL,
      FileManager.default.fileExists(atPath: url.path),
      let data = try? Data(contentsOf: url)
    else {
      return nil
    }
    return try? JSONDecoder().decode(SharedBudgetData.self, from: data)
  }
}
