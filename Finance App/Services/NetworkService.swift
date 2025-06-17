//
//  NetworkService.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation

/// Generic helper for JSON-based POST and GET requests.
enum HTTPMethod: String { case get = "GET", post = "POST" }

struct NetworkService {
    /// Executes a JSON POST request.
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

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                return DispatchQueue.main.async { completion(.failure(error)) }
            }
            guard let data = data else {
                let err = NSError(domain: "NetworkService", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "No data"])
                return DispatchQueue.main.async { completion(.failure(err)) }
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        .resume()
    }

    /// Executes a GET request with optional query items.
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
            let err = NSError(domain: "NetworkService", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Bad URL"])
            return DispatchQueue.main.async { completion(.failure(err)) }
        }

        URLSession.shared.dataTask(with: finalURL) { data, _, error in
            if let error = error {
                return DispatchQueue.main.async { completion(.failure(error)) }
            }
            guard let data = data else {
                let err = NSError(domain: "NetworkService", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "No data"])
                return DispatchQueue.main.async { completion(.failure(err)) }
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        .resume()
    }
}

