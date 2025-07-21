//
//  NetworkService.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation
import FirebaseAuth

/// Generic helper for JSON-based POST and GET requests.
enum HTTPMethod: String { case get = "GET", post = "POST" }

struct NetworkService {

    private static func executeRequest<T: Decodable>(
        _ request: URLRequest,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // 1. Check for a current user. If none exists, the session is effectively expired.
        guard let user = Auth.auth().currentUser else {
            DispatchQueue.main.async { completion(.failure(.sessionExpired)) }
            return
        }

        // 2. Get a fresh, valid token. Firebase handles caching and refreshing behind the scenes.
        user.getIDTokenResult(forcingRefresh: false) { result, error in
            // 3. Handle token errors. This is where we detect an invalid session.
            if let error = error {
                // Check if the error code indicates an expired or invalid token.
                let errorCode = (error as NSError).code
                if errorCode == AuthErrorCode.userTokenExpired.rawValue ||
                   errorCode == AuthErrorCode.invalidUserToken.rawValue ||
                   errorCode == AuthErrorCode.userNotFound.rawValue {
                    
                    DispatchQueue.main.async { completion(.failure(.sessionExpired)) }
                } else {
                    DispatchQueue.main.async { completion(.failure(.serverError(message: error.localizedDescription))) }
                }
                return
            }
            
            guard let idToken = result?.token else {
                DispatchQueue.main.async { completion(.failure(.sessionExpired)) }
                return
            }
            
            // 4. Add the valid token to the request's Authorization header.
            var authenticatedRequest = request
            authenticatedRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            // 5. Perform the data task as before.
            URLSession.shared.dataTask(with: authenticatedRequest) { data, response, error in
                if let error = error {
                    return DispatchQueue.main.async { completion(.failure(.unknown(error))) }
                }
                
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let message = "Server returned status \(httpResponse.statusCode)"
                    return DispatchQueue.main.async { completion(.failure(.serverError(message: message))) }
                }

                guard let data = data else {
                    return DispatchQueue.main.async { completion(.failure(.serverError(message: "No data received"))) }
                }
                
                // 6. Decode the JSON response, now using our custom error for decoding issues.
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async { completion(.success(decoded)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(.decodingError(error))) }
                }
            }
            .resume()
        }
    }

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

    /// Executes an authenticated GET request with optional query items.
    static func getJSON<T: Decodable>(
        from url: URL,
        queries: [String: String]? = nil,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if let queries = queries {
            comps.queryItems = queries.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let finalURL = comps.url else {
            return DispatchQueue.main.async { completion(.failure(.badURL)) }
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        executeRequest(request, decodeTo: type, completion: completion)
    }
}


