//
//  DataService.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import Foundation

// MARK: - Network Request Models (NEW)
// These new structs provide a type-safe way to create the JSON body for POST requests.
// They are based on the parameters from your original DataService functions.

struct AISuggestionRequest: Encodable {
    let transactions: [Transaction]
    let weeklyBudget: Int
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case weeklyBudget = "weekly_budget"
    }
}

struct AIReallocationRequest: Encodable {
    // Note: It's better to use a Codable struct for 'currentPlan' instead of [String: [String: Any]]
    // but for now, this matches your original code. For true safety, 'currentPlan' should also be a struct.
    let transactions: [Transaction]
    let currentPlan: [String: PlanItem]
    let lockedCategory: String
    let newValue: Int
    let totalBudget: Int
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case currentPlan = "current_plan"
        case lockedCategory = "locked_category"
        case newValue = "new_value"
        case totalBudget = "total_budget"
    }
}

struct SaveBudgetPlanRequest: Encodable {
    let budgetPlan: [String: CategoryBudget]
    let totalBudget: Int
}


// MARK: - DataService (Refactored)

/// Encapsulates all authenticated network calls to your backend.
class DataService {
    
    /// Fetches account summaries for the main dashboard.
    static func loadSummaries(completion: @escaping (Result<[AccountSummary], NetworkError>) -> Void) { // <-- UPDATED
        NetworkService.getJSON(from: API.summaries.url, decodeTo: SummariesResponse.self) { result in
            completion(result.map { $0.summaries })
        }
    }
    
    /// Fetches transactions for a given period.
    static func loadTransactions(
        startDate: String,
        endDate: String,
        completion: @escaping (Result<[Transaction], NetworkError>) -> Void // <-- UPDATED
    ) {
        let queries = ["start_date": startDate, "end_date": endDate]
        
        NetworkService.getJSON(from: API.transactions.url, queries: queries, decodeTo: TransactionsResponse.self) { result in
            completion(result.map { $0.transactions })
        }
    }
    
    /// Fetches an AI-generated spending plan.
    static func fetchAISuggestion(
        transactions: [Transaction],
        budget: Int,
        completion: @escaping (Result<[String: CategoryBudget], NetworkError>) -> Void // <-- UPDATED
    ) {
        let requestBody = AISuggestionRequest(transactions: transactions, weeklyBudget: budget)
        
        NetworkService.postJSON(to: API.aiSummary.url, body: requestBody, decodeTo: AISuggestionResponse.self) { result in
            completion(result.map { $0.suggestion })
        }
    }
    
    // NOTE: For full type-safety, the 'currentPlan' parameter should also be a Codable struct.
    static func fetchAIReallocation(
        transactions: [Transaction],
        currentPlan: [String: PlanItem],
        lockedCategory: String,
        newValue: Int,
        totalBudget: Int,
        completion: @escaping (Result<[String: CategoryBudget], NetworkError>) -> Void // <-- UPDATED
    ) {
        let requestBody = AIReallocationRequest(
            transactions: transactions,
            currentPlan: currentPlan,
            lockedCategory: lockedCategory,
            newValue: newValue,
            totalBudget: totalBudget
        )
        
        NetworkService.postJSON(to: API.aiSummary.url, body: requestBody, decodeTo: AISuggestionResponse.self) { result in
            completion(result.map { $0.suggestion })
        }
    }
    
    /// Saves the user's current budget plan to the backend.
    static func saveBudgetPlan(
        plan: [String: CategoryBudget],
        totalBudget: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let requestBody = SaveBudgetPlanRequest(budgetPlan: plan, totalBudget: totalBudget)
        
        NetworkService.postJSON(to: API.budget.url, body: requestBody, decodeTo: GenericSuccessResponse.self) { result in
            switch result {
            case .success(let response):
                completion(response.success)
            case .failure(let error):
                // This function doesn't pass the error up, so it's fine as is.
                print("❌ Failed to save budget plan:", error)
                completion(false)
            }
        }
    }
    
    /// Loads an existing budget plan from the backend.
    static func loadBudgetPlan(completion: @escaping (Result<LoadBudgetResponse, NetworkError>) -> Void) { // <-- UPDATED
        NetworkService.getJSON(from: API.budget.url, decodeTo: LoadBudgetResponse.self, completion: completion)
    }
}

