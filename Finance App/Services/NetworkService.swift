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

    // --- NEW: A private, centralized executor that handles authentication ---
    private static func executeRequest<T: Decodable>(
        _ request: URLRequest,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // 1. Get the current user's Firebase ID token.
        Auth.auth().currentUser?.getIDToken { idToken, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let idToken = idToken else {
                let err = NSError(domain: "NetworkService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."])
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            
            // 2. Add the token to the request's Authorization header.
            var authenticatedRequest = request
            authenticatedRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            // 3. Perform the data task with the authenticated request.
            URLSession.shared.dataTask(with: authenticatedRequest) { data, response, error in
                if let error = error {
                    return DispatchQueue.main.async { completion(.failure(error)) }
                }
                
                // Optional: Check for HTTP errors
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                     let err = NSError(domain: "NetworkService", code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: "Server returned status \(httpResponse.statusCode)"])
                    return DispatchQueue.main.async { completion(.failure(err)) }
                }

                guard let data = data else {
                    let err = NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    return DispatchQueue.main.async { completion(.failure(err)) }
                }
                
                // 4. Decode the JSON response.
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async { completion(.success(decoded)) }
                } catch {
                    // For debugging: print the raw data if decoding fails
                    print("Decoding Error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON response: \(jsonString)")
                    }
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
            .resume()
        }
    }

    /// Executes an authenticated JSON POST request.
    static func postJSON<T: Decodable>(
        to url: URL,
        body: [String: Any],
        decodeTo type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Use our new central executor
        executeRequest(request, decodeTo: type, completion: completion)
    }

    /// Executes an authenticated GET request with optional query items.
    static func getJSON<T: Decodable>(
        from url: URL,
        queries: [String: String]? = nil,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if let queries = queries {
            comps.queryItems = queries.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let finalURL = comps.url else {
            let err = NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"])
            return DispatchQueue.main.async { completion(.failure(err)) }
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        // Use our new central executor
        executeRequest(request, decodeTo: type, completion: completion)
    }
}


