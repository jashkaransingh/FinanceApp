//
//  DataService.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import UIKit
import Foundation

/// Encapsulates all network calls to your backend.
class DataService {
    
    // MARK: – Public API
    
    /// Fetches account summaries for the connected bank.
    /// - Parameters:
    ///   - accessToken: Plaid access token for authentication.
    ///   - completion: Called on the main thread with fetched summaries or empty on failure.
    static func loadSummariesFromBackend(
        accessToken: String,
        completion: @escaping ([AccountSummary]) -> Void
    ) {
        guard let url = API.makeURL(
            path: "/summaries",
            queries: ["access_token": accessToken]
        ) else {
            return DispatchQueue.main.async { completion([]) }
        }
        
        performRequest(url: url, decodeTo: SummariesResponse.self) { result in
            switch result {
            case .success(let wrapper):
                completion(wrapper.summaries)
            case .failure:
                completion([])
            }
        }
    }
    
    /// Fetches transactions for a given period (today/week/month).
    static func loadTransactions(
        accessToken: String,
        period: String,
        completion: @escaping ([Transaction]) -> Void
    ) {
        guard let url = API.makeURL(
            path: "/transactions",
            queries: ["access_token": accessToken, "period": period]
        ) else {
            return DispatchQueue.main.async { completion([]) }
        }
        
        performRequest(url: url, decodeTo: TransactionsResponse.self) { result in
            switch result {
            case .success(let resp):
                completion(resp.transactions)
            case .failure:
                completion([])
            }
        }
    }
    
    /// Fetches transactions between two dates.
    static func loadTransactions(
        accessToken: String,
        startDate: String,
        endDate: String,
        completion: @escaping ([Transaction]) -> Void
    ) {
        guard let url = API.makeURL(
            path: "/transactions",
            queries: [
                "access_token": accessToken,
                "start_date": startDate,
                "end_date": endDate
            ]
        ) else {
            return DispatchQueue.main.async { completion([]) }
        }
        
        performRequest(url: url, decodeTo: TransactionsResponse.self) { result in
            switch result {
            case .success(let resp):
                completion(resp.transactions)
            case .failure:
                completion([])
            }
        }
    }
    
    // MARK: – Private Helpers
    
    /// Generic executor for GET requests that decode JSON into the given model.
    private static func performRequest<T: Decodable>(
        url: URL,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Network error or missing data
            if let error = error {
                print("Network error:", error)
                return DispatchQueue.main.async { completion(.failure(error)) }
            }
            guard let data = data else {
                let err = NSError(
                    domain: "DataService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"]
                )
                return DispatchQueue.main.async { completion(.failure(err)) }
            }
            
            // Decode JSON
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                print("Decoding error:", error)
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        .resume()
    }
    static func fetchAISummary(
        budget: Int = 100,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = API.makeURL(path: "/ai/weekly_summary") else {
            return completion(.failure(NSError(domain: "URL", code: -1)))
        }
        
        let body: [String: Any] = [
            "weekly_budget": budget,
            "transactions": []  // Empty for now or fetch recent ones if needed
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let suggestion = json["suggestion"] as? [String: Any] else {
                return completion(.failure(NSError(domain: "Invalid format", code: 0)))
            }
            completion(.success(suggestion))
        }.resume()
    }
}




