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
        // Ensure there is a signed-in user
        guard let user = Auth.auth().currentUser else {
            DispatchQueue.main.async { completion(.failure(.sessionExpired)) }
            return
        }
        
        // Obtain a valid ID token
        user.getIDTokenResult(forcingRefresh: false) { result, error in
            if let error = error {
                let errorCode = (error as NSError).code
                if errorCode == AuthErrorCode.userTokenExpired.rawValue ||
                    errorCode == AuthErrorCode.invalidUserToken.rawValue ||
                    errorCode == AuthErrorCode.userNotFound.rawValue {
                    
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
            
            // Attach the token to the Authorization header
            var authenticatedRequest = request
            authenticatedRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: authenticatedRequest) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async { completion(.failure(.unknown(error))) }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    let message = "Server returned status \(httpResponse.statusCode)"
                    DispatchQueue.main.async { completion(.failure(.serverError(message: message))) }
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
                    // Decoding diagnostics for development
                    print("Decoding error for type \(T.self): \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON response:\n\(jsonString)")
                    }
                    DispatchQueue.main.async { completion(.failure(.decodingError(error))) }
                }
            }
            .resume()
        }
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
