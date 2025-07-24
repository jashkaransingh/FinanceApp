//
//  PlaidResponses.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation

// MARK: - Core Data Models

struct Transaction: Codable, Hashable {
    let name: String
    let amount: Double
    let date: String // "yyyy-MM-dd"
    let category: String
}

struct AccountSummary: Codable {
    let periodTitle: String      // e.g. "Spent Today"
    let amount: Double           // e.g. 64.30
    let percentage: Double       // e.g. -11 (negative = down)
    let subtitle: String         // e.g. "Yesterday $72.50"
    let usesPieIcon: Bool        // true for “This Month”
}

/// The structure of one item within the AI's budget suggestion.
struct CategoryBudget: Codable {
    let amount: Int
    let percent: Int
    let subtitle: String
}
struct PlanItem: Codable {
    let amount: Double
    let percent: Double
    let subtitle: String
}

struct EmptyBody: Encodable { }

// Represents the request to exchange a public token.
struct ExchangeTokenRequest: Encodable {
    let publicToken: String
    
    enum CodingKeys: String, CodingKey {
        case publicToken = "public_token"
    }
}


struct AISuggestionResponse: Decodable {
    // This now correctly decodes the dynamic keys (e.g., "Food", "Transportation")
    // into a dictionary where the value is a typed CategoryBudget struct.
    let suggestion: [String: CategoryBudget]
}

// MARK: - API Response Wrapper Models

/// Used for endpoints that return a list of transactions.
struct TransactionsResponse: Decodable {
    let transactions: [Transaction]
}

/// Used for the /summaries endpoint.
struct SummariesResponse: Decodable {
    let summaries: [AccountSummary]
}

/// Used for the /create_link_token endpoint.
struct LinkTokenResponse: Decodable {
    let link_token: String
}


/// A generic response for any endpoint that just returns {"success": true}.
struct GenericSuccessResponse: Decodable {
    let success: Bool
}
struct LoadBudgetResponse: Decodable {
    let budgetPlan: [String: CategoryBudget]
    let totalBudget: Int
}

