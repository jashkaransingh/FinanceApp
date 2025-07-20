//
//  SharedDataManager.swift
//  Finance App
//
//  Created by Jas  on 7/19/25.
//

import Foundation

// A Codable struct to easily save/load the data your widget needs.
struct SharedBudgetData: Codable {
    let today: Double
    let yesterday: Double
    let weeklyBudget: Double
}

// Manages reading and writing data to the shared App Group container.
class SharedDataManager {
    // The App Group ID you created in Step 1.
    // !! IMPORTANT: Replace with your actual App Group ID !!
    private let appGroupID = "group.com.singh.financeapp"

    // The specific file URL within the shared container.
    private var sharedFileURL: URL? {
        guard let groupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("Error: Could not get shared container URL.")
            return nil
        }
        return groupContainer.appendingPathComponent("sharedBudgetData.json")
    }

    // Saves the budget data to the shared JSON file.
    func save(_ data: SharedBudgetData) {
        guard let url = sharedFileURL else { return }
        do {
            let encodedData = try JSONEncoder().encode(data)
            try encodedData.write(to: url)
            print("Successfully saved data to shared container.")
        } catch {
            print("Error saving shared data: \(error.localizedDescription)")
        }
    }

    // Loads the budget data from the shared JSON file.
    func load() -> SharedBudgetData? {
        guard let url = sharedFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decodedData = try JSONDecoder().decode(SharedBudgetData.self, from: data)
            return decodedData
        } catch {
            print("Error loading shared data: \(error.localizedDescription)")
            return nil
        }
    }
}
