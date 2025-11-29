//
//  FrequentMerchant.swift
//  Finance App
//
//  Created by Jas  on 11/26/25.
//

import Foundation

/// Represents a single, high-frequency merchant (a "habit").
/// This is decoded from the new `/ai/frequent_merchants` endpoint.
struct FrequentMerchant: Codable, Identifiable, Hashable {
    let id = UUID() // Makes it easy to use in a SwiftUI List later
    let name: String
    let totalVisits: Int
    let medianCost: Double
    let category: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FrequentMerchant, rhs: FrequentMerchant) -> Bool {
        return lhs.id == rhs.id
    }
    
    // This tells Swift how to decode the snake_case JSON from Python
    // into our camelCase properties.
    enum CodingKeys: String, CodingKey {
        case name
        case totalVisits = "total_visits"
        case medianCost = "median_cost"
        case category
    }
}

/// This is the top-level object decoded from the `/ai/frequent_merchants` JSON.
struct FrequentMerchantsResponse: Codable {
    let merchants: [FrequentMerchant]
}
