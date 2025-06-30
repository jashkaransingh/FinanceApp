//
//  DataService.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import Foundation

// Encapsulates all authenticated network calls to your backend.
class DataService {

    /// Fetches account summaries for the main dashboard.
    static func loadSummaries(completion: @escaping (Result<[AccountSummary], Error>) -> Void) {
        NetworkService.getJSON(
            from: API.summaries.url,
            decodeTo: SummariesResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.summaries))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Fetches transactions for a given period.
    static func loadTransactions(
        startDate: String,
        endDate: String,
        completion: @escaping (Result<[Transaction], Error>) -> Void
    ) {
        let queries = ["start_date": startDate, "end_date": endDate]
        NetworkService.getJSON(
            from: API.transactions.url,
            queries: queries,
            decodeTo: TransactionsResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.transactions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Fetches an AI-generated spending plan.
    static func fetchAISuggestion(
        transactions: [Transaction],
        budget: Int,
        completion: @escaping (Result<[String: CategoryBudget], Error>) -> Void
    ) {
        let transactionPayload = transactions.map { ["name": $0.name, "amount": $0.amount] }
        let body: [String: Any] = [
            "transactions": transactionPayload,
            "weekly_budget": budget
        ]

        NetworkService.postJSON(
            to: API.aiSummary.url,
            body: body,
            decodeTo: AISuggestionResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.suggestion))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    /// Fetches an AI-based reallocation plan.
        static func fetchAIReallocation(
            transactions: [Transaction],
            currentPlan: [String: [String: Any]],
            lockedCategory: String,
            newValue: Int,
            totalBudget: Int,
            completion: @escaping (Result<[String: CategoryBudget], Error>) -> Void
        ) {
            let payload: [String: Any] = [
                "transactions": transactions.map { ["name": $0.name, "amount": $0.amount] },
                "current_plan": currentPlan,
                "locked_category": lockedCategory,
                "new_value": newValue,
                "total_budget": totalBudget
            ]

            // We re-use the same AI endpoint and response model
            NetworkService.postJSON(
                to: API.aiSummary.url, // Assumes your AI endpoint handles both initial and reallocation
                body: payload,
                decodeTo: AISuggestionResponse.self
            ) { result in
                switch result {
                case .success(let response):
                    completion(.success(response.suggestion))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    /// Saves the user's current budget plan to Firestore via the backend.
        static func saveBudgetPlan(
            plan: [String: CategoryBudget],
            totalBudget: Int,
            completion: @escaping (Bool) -> Void
        ) {
            // The plan needs to be converted to [String: Any] for JSON serialization.
            let planPayload = plan.mapValues { ["amount": $0.amount, "percent": $0.percent, "subtitle": $0.subtitle] }
            
            let body: [String: Any] = [
                "budgetPlan": planPayload,
                "totalBudget": totalBudget
            ]
            
            NetworkService.postJSON(
                to: API.budget.url,
                body: body,
                decodeTo: GenericSuccessResponse.self
            ) { result in
                switch result {
                case .success(let response):
                    completion(response.success)
                case .failure(let error):
                    print("❌ Failed to save budget plan:", error)
                    completion(false)
                }
            }
        }
        
        /// Loads an existing budget plan from Firestore via the backend.
        static func loadBudgetPlan(completion: @escaping (Result<LoadBudgetResponse, Error>) -> Void) {
            NetworkService.getJSON(
                from: API.budget.url,
                decodeTo: LoadBudgetResponse.self,
                completion: completion
            )
        }
}

