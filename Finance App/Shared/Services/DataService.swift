//
//  DataService.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import Foundation

// MARK: - Network Request Models

/// Request body for the frequent merchants endpoint.
struct AIFrequentMerchantsRequest: Encodable {
    let transactions: [Transaction]
}

/// Request body for the weekly summary endpoint.
struct AISuggestionRequest: Encodable {
    let transactions: [Transaction]
    let totalBudget: Int
    let selectedMerchants: [String]?
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case totalBudget = "total_budget"
        case selectedMerchants = "selected_merchants"
    }
}

/// Request body for saving a budget plan.
struct SaveBudgetPlanRequest: Encodable {
    let budgetPlan: [String: BudgetPlanItem]
    let totalBudget: Int
}

// MARK: - DataService

/// Encapsulates all authenticated network calls to the backend.
final class DataService {
    
    /// Fetches account summaries for the dashboard.
    static func loadSummaries(
        completion: @escaping (Result<[AccountSummary], NetworkError>) -> Void
    ) {
        NetworkService.getJSON(
            from: API.summaries.url,
            decodeTo: SummariesResponse.self
        ) { result in
            completion(result.map { $0.summaries })
        }
    }
    
    /// Fetches transactions for a given period or date range.
    static func loadTransactions(
        startDate: String? = nil,
        endDate: String? = nil,
        period: String? = nil,
        completion: @escaping (Result<[Transaction], NetworkError>) -> Void
    ) {
        var queries: [String: String] = [:]

        if let period {
            queries["period"] = period
        } else {
            if let startDate { queries["start_date"] = startDate }
            if let endDate   { queries["end_date"]   = endDate }
        }

        NetworkService.getJSON(
            from: API.transactions.url,
            queries: queries.isEmpty ? nil : queries,
            decodeTo: TransactionsResponse.self
        ) { result in
            completion(result.map { $0.transactions })
        }
    }

    
    // MARK: - AI Functions
    
    /// Fetches the user's top spending merchants.
    static func fetchFrequentMerchants(
        transactions: [Transaction],
        completion: @escaping (Result<[FrequentMerchant], NetworkError>) -> Void
    ) {
        let body = AIFrequentMerchantsRequest(transactions: transactions)
        
        NetworkService.postJSON(
            to: API.aiFrequentMerchants.url,
            body: body,
            decodeTo: FrequentMerchantsResponse.self
        ) { result in
            completion(result.map { $0.merchants })
        }
    }
    
    /// Fetches an AI-generated spending plan based on the provided transactions and merchants.
    static func fetchAISuggestion(
        transactions: [Transaction],
        budget: Int,
        selectedMerchants: [String]?,
        completion: @escaping (Result<[String: BudgetPlanItem], NetworkError>) -> Void
    ) {
        let body = AISuggestionRequest(
            transactions: transactions,
            totalBudget: budget,
            selectedMerchants: selectedMerchants
        )
        
        NetworkService.postJSON(
            to: API.aiSummary.url,
            body: body,
            decodeTo: AISuggestionResponse.self
        ) { result in
            completion(result.map { $0.suggestion })
        }
    }
    
    /// Saves the user's current budget plan to the backend.
    static func saveBudgetPlan(
        plan: [String: BudgetPlanItem],
        totalBudget: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let body = SaveBudgetPlanRequest(
            budgetPlan: plan,
            totalBudget: totalBudget
        )
        
        NetworkService.postJSON(
            to: API.budget.url,
            body: body,
            decodeTo: GenericSuccessResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(response.success)
            case .failure(let error):
                print("Error: Failed to save budget plan: \(error)")
                completion(false)
            }
        }
    }
    
    /// Loads an existing budget plan from the backend.
    static func loadBudgetPlan(
        completion: @escaping (Result<LoadBudgetPlanResponse, NetworkError>) -> Void
    ) {
        NetworkService.getJSON(
            from: API.budget.url,
            decodeTo: LoadBudgetPlanResponse.self,
            completion: completion
        )
    }
}
