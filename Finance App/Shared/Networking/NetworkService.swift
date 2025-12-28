//
//  NetworkService.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation
import FirebaseAuth

// MARK: - Types

/// Supported HTTP methods for JSON-based requests.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

// MARK: - Service

/// Helper for authenticated JSON GET/POST requests.
/// All completion handlers are invoked on the main queue.
struct NetworkService {
    
    // MARK: - Core Executor
    
    private static func executeRequest<T: Decodable>(
        _ request: URLRequest,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            DispatchQueue.main.async { completion(.failure(.sessionExpired)) }
            return
        }
        
        func run(forceRefreshToken: Bool) {
            user.getIDTokenResult(forcingRefresh: forceRefreshToken) { result, error in
                if let error = error {
                    let code = (error as NSError).code
                    if code == AuthErrorCode.userTokenExpired.rawValue ||
                        code == AuthErrorCode.invalidUserToken.rawValue ||
                        code == AuthErrorCode.userNotFound.rawValue {
                        DispatchQueue.main.async { completion(.failure(.sessionExpired)) }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(.serverError(message: error.localizedDescription)))
                        }
                    }
                    return
                }
                
                guard let idToken = result?.token else {
                    DispatchQueue.main.async { completion(.failure(.sessionExpired)) }
                    return
                }
                
                var authenticatedRequest = request
                authenticatedRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: authenticatedRequest) { data, response, error in
                    if let error = error {
                        DispatchQueue.main.async { completion(.failure(.unknown(error))) }
                        return
                    }
                    
                    guard let http = response as? HTTPURLResponse else {
                        DispatchQueue.main.async {
                            completion(.failure(.serverError(message: "Invalid server response")))
                        }
                        return
                    }

                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

                    // Retry once on 401 (expired/invalid token)
                    if http.statusCode == 401, forceRefreshToken == false {
                        run(forceRefreshToken: true)
                        return
                    }

                    // Retry once on 403 ONLY if it’s the email verify case
                    if http.statusCode == 403, forceRefreshToken == false, body.contains("EMAIL_NOT_VERIFIED") {
                        run(forceRefreshToken: true)
                        return
                    }

                    
                    guard (200...299).contains(http.statusCode) else {
                        let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        let msg = "Server returned \(http.statusCode). \(body)"
                        DispatchQueue.main.async { completion(.failure(.serverError(message: msg))) }
                        return
                    }
                    
                    guard let data = data else {
                        DispatchQueue.main.async {
                            completion(.failure(.serverError(message: "No data received")))
                        }
                        return
                    }
                    
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        DispatchQueue.main.async { completion(.success(decoded)) }
                    } catch {
                        print("Decoding error for type \(T.self): \(error)")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Raw JSON response:\n\(jsonString)")
                        }
                        DispatchQueue.main.async { completion(.failure(.decodingError(error))) }
                    }
                }.resume()
            }
        }
        
        run(forceRefreshToken: false)
    }
    
    // MARK: - Public API
    
    /// Executes an authenticated JSON POST request.
    static func postJSON<T: Decodable, B: Encodable>(
        to url: URL,
        body: B,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        executeRequest(request, decodeTo: type, completion: completion)
    }
    
    /// Executes an authenticated JSON GET request with optional query items.
    static func getJSON<T: Decodable>(
        from url: URL,
        queries: [String: String]? = nil,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        if let queries = queries {
            components.queryItems = queries.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = components.url else {
            DispatchQueue.main.async { completion(.failure(.badURL)) }
            return
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        executeRequest(request, decodeTo: type, completion: completion)
    }
}
