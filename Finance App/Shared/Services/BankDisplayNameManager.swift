//
//  BankDisplayNameManager.swift
//  Finance App
//
//  Created by Jas  on 8/5/25.
//

import Foundation
import LinkKit

/// Loads a mapping of Plaid institution IDs → clean display names and
/// provides a helper to resolve a friendly name from Link metadata.
final class BankDisplayNameManager {
    
    static let shared = BankDisplayNameManager()
    private init() { loadMappingFromJSON() }
    
    private var displayNameMap: [String: String] = [:]
    
    // MARK: - Loading
    
    private func loadMappingFromJSON() {
        guard let url = Bundle.main.url(forResource: "BankDisplayNames", withExtension: "json") else {return}
        guard let data = try? Data(contentsOf: url) else {return}
        guard let map = try? JSONDecoder().decode([String: String].self, from: data) else {return}
        displayNameMap = map
#if DEBUG
        print("✅ Loaded \(displayNameMap.count) bank display names.")
#endif
    }
    
    // MARK: - API
    
    /// Returns a friendly display name for a Plaid institution, falling back to the original.
    public func displayName(for institution: Institution) -> String {
        displayNameMap[institution.id] ?? institution.name
    }
}

