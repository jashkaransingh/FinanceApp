//
//  API.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation

enum API {/// Common path and URL helpers for all API endpoints
    /// The host portion of every request.
    static let host = Environment.baseURL

    /// Builds a URL with the given path and query items.
    /// - Parameters:
    ///   - path: Endpoint path (e.g. "/summaries")
    ///   - queries: Optional dictionary of query parameters.
    /// - Returns: A `URL` or `nil` if invalid.
    static func makeURL(path: String, queries: [String: String]? = nil) -> URL? {
        var comps = URLComponents(string: host + path)
        comps?.queryItems = queries?.map { URLQueryItem(name: $0.key, value: $0.value) }
        return comps?.url
    }
}

