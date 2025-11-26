//
//  DataService.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import Foundation

// MARK: - Network Request Models

// These structs provide a type-safe way to create the JSON body for POST requests
struct AISuggestionRequest: Encodable {
    let transactions: [Transaction]
    let weeklyBudget: Int
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case weeklyBudget = "weekly_budget"
    }
}

struct AIReallocationRequest: Encodable {
    let transactions: [Transaction]
    let currentPlan: [String: PlanItem]
    let lockedCategory: String
    let newValue: Int
    let totalBudget: Int
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case currentPlan   = "current_plan"
        case lockedCategory = "locked_category"
        case newValue      = "new_value"
        case totalBudget   = "total_budget"
    }
}

struct SaveBudgetPlanRequest: Encodable {
    let budgetPlan: [String: CategoryBudget]
    let totalBudget: Int
}

// MARK: - DataService

/// Encapsulates all authenticated network calls to your backend.
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
    
    /// Fetches transactions for a given period.
    /// Fetches transactions for a given period.
        static func loadTransactions(
            startDate: String? = nil,
            endDate: String? = nil,
            period: String? = nil,
            completion: @escaping (Result<[Transaction], NetworkError>) -> Void
        ) {
            
    #if DEBUG
            // --- THIS IS THE NEW LOGIC ---
            // FOR TESTING: Override the network call to fetch a clean test scenario
            // instead of live (and messy) Plaid data.
            
            // 1. Construct the URL to your test endpoint.
            //    (You must replace "127.0.0.1" with your computer's IP if testing on a real device)
            guard let url = URL(string: "http://127.0.0.1:5050/test/scenario/college_student") else {
                completion(.failure(.badURL))
                return
            }
            
            print("✅ DEBUG: Loading 'college_student' test data...")
            
            // 2. Make the network call to the test endpoint
            NetworkService.getJSON(
                from: url,
                queries: [:], // No queries needed
                decodeTo: TransactionsResponse.self
            ) { result in
                completion(result.map { $0.transactions })
            }
            
    #else
            // --- THIS IS YOUR ORIGINAL PRODUCTION CODE ---
            // It will run as normal when you are not in a DEBUG build.
            
            // 1. Start with an empty dictionary of the correct type.
            var queries: [String: String] = [:]
            
            // 2. Conditionally add the parameters that exist.
            if let period = period {
                queries["period"] = period
            } else if let startDate = startDate, let endDate = endDate {
                queries["start_date"] = startDate
                queries["end_date"] = endDate
            }
            
            // 3. Make the network call with the safely-built dictionary.
            NetworkService.getJSON(
                from: API.transactions.url,
                queries: queries,
                decodeTo: TransactionsResponse.self
            ) { result in
                completion(result.map { $0.transactions })
            }
    #endif
        }
    
    /// Fetches an AI-generated spending plan.
    static func fetchAISuggestion(
        transactions: [Transaction],
        budget: Int,
        completion: @escaping (Result<[String: CategoryBudget], NetworkError>) -> Void
    ) {
        let body = AISuggestionRequest(transactions: transactions, weeklyBudget: budget)
        NetworkService.postJSON(
            to: API.aiSummary.url,
            body: body,
            decodeTo: AISuggestionResponse.self
        ) { result in
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
        completion: @escaping (Result<[String: CategoryBudget], NetworkError>) -> Void
    ) {
        let body = AIReallocationRequest(
            transactions: transactions,
            currentPlan: currentPlan,
            lockedCategory: lockedCategory,
            newValue: newValue,
            totalBudget: totalBudget
        )
        
        NetworkService.postJSON(
            to: API.aiReallocate.url,
            body: body,
            decodeTo: AISuggestionResponse.self
        ) { result in
            completion(result.map { $0.suggestion })
        }
    }
    
    /// Saves the user's current budget plan to the backend.
    static func saveBudgetPlan(
        plan: [String: CategoryBudget],
        totalBudget: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let body = SaveBudgetPlanRequest(budgetPlan: plan, totalBudget: totalBudget)
        NetworkService.postJSON(
            to: API.budget.url,
            body: body,
            decodeTo: GenericSuccessResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(response.success)
            case .failure(let error):
                print("Failed to save budget plan:", error)
                completion(false)
            }
        }
    }
    
    /// Loads an existing budget plan from the backend.
    static func loadBudgetPlan(
        completion: @escaping (Result<LoadBudgetResponse, NetworkError>) -> Void
    ) {
        NetworkService.getJSON(
            from: API.budget.url,
            decodeTo: LoadBudgetResponse.self,
            completion: completion
        )
    }
}

