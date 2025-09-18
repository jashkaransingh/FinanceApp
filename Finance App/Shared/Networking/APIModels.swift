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
    let date: String // "yyyy-MM-dd" format
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

// MARK: - Direct Responses

struct AISuggestionResponse: Decodable {
    /// Dynamic category keys (e.g., "Food", "Transportation") map to typed values.
    let suggestion: [String: CategoryBudget]
}

struct TransactionsResponse: Decodable {
    let transactions: [Transaction]
}

struct SummariesResponse: Decodable {
    let summaries: [AccountSummary]
}

struct LinkTokenResponse: Decodable {
    let link_token: String
}

struct GenericSuccessResponse: Decodable {
    let success: Bool
}

struct LoadBudgetResponse: Decodable {
    let budgetPlan: [String: CategoryBudget]
    let totalBudget: Int
}

