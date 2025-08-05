//
//  BankDisplayNameManager.swift
//  Finance App
//
//  Created by Jas  on 8/5/25.
//

import Foundation
// Make sure LinkKit is imported if it's not already, so it knows what LinkSuccess is.
import LinkKit

/// Manages loading and providing custom, user-friendly bank display names.
/// This class is a singleton to ensure the mapping is loaded only once.
final class BankDisplayNameManager {

    /// The shared singleton instance.
    static let shared = BankDisplayNameManager()

    /// The dictionary that holds the mapping from institution ID to display name.
    /// It's private to prevent outside modification.
    private var displayNameMap: [String: String] = [:]

    /// The initializer is private to enforce the singleton pattern.
    /// It calls the method to load the names from the bundled JSON file.
    private init() {
        loadMappingFromJSON()
    }

    /// Loads the `BankDisplayNames.json` file from the app bundle and decodes it
    /// into our dictionary.
    private func loadMappingFromJSON() {
        // 1. Find the URL for the JSON file in our app bundle.
        guard let url = Bundle.main.url(forResource: "BankDisplayNames", withExtension: "json") else {
            print("⚠️ Error: BankDisplayNames.json file not found in the app bundle.")
            return
        }

        // 2. Try to load the data from the file URL.
        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ Error: Could not load data from BankDisplayNames.json.")
            return
        }

        // 3. Try to decode the JSON data into a [String: String] dictionary.
        guard let decodedMap = try? JSONDecoder().decode([String: String].self, from: data) else {
            print("⚠️ Error: Failed to decode BankDisplayNames.json.")
            return
        }

        // 4. Assign the successfully decoded map to our property.
        self.displayNameMap = decodedMap
        print("✅ Successfully loaded \(displayNameMap.count) bank display names.")
    }

    // --- THIS IS THE CORRECTED LINE ---
    /// Returns a clean display name for a given Plaid institution.
    /// - Parameter institution: The `Institution` object from the Plaid Link success metadata.
    /// - Returns: The custom display name if it exists in the map, otherwise falls back to the original institution name.
    public func displayName(for institution: Institution) -> String {
            return displayNameMap[institution.id] ?? institution.name
        }
    }
