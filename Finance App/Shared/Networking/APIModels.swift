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
    let periodTitle: String     // e.g. "Spent Today"
    let amount: Double          // e.g. 64.30
    let percentage: Double      // e.g. -11 (negative = down)
    let subtitle: String        // e.g. "Yesterday $72.50"
    let usesPieIcon: Bool       // true for “This Month”
}



struct BudgetPlanItem: Codable, Identifiable, Hashable {
    let id = UUID()
    let amount: Int
    let percent: Int
    let subtitle: String
    let category: String // For coloring
    let costPerVisit: Double
    let visits: Int
    
    // We need this for the `currentPlan` dictionary in the VC
    init(amount: Int, percent: Int, subtitle: String, category: String, costPerVisit: Double, visits: Int) {
        self.amount = amount
        self.percent = percent
        self.subtitle = subtitle
        self.category = category
        self.costPerVisit = costPerVisit
        self.visits = visits
    }
    
    enum CodingKeys: String, CodingKey {
        case amount, percent, subtitle, category
        case costPerVisit = "cost_per_visit"
        case visits
    }
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

/// This REPLACES the old `AISuggestionResponse`.
/// The backend returns a dictionary where keys are category names.
/// e.g., { "Food & Dining": { ... } }
struct AISuggestionResponse: Decodable {
    let suggestion: [String: BudgetPlanItem]
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

/// This REPLACES the old `LoadBudgetResponse`.
/// It's the response from the `GET /budget` endpoint.
struct LoadBudgetPlanResponse: Decodable {
    let budgetPlan: [String: BudgetPlanItem]
    let totalBudget: Int
}

