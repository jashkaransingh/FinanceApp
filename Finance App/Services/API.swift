//
//  API.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation

/// Defines all backend endpoints.
enum API {
    // This host should point to your Flask server's address.
    // Make sure this is configured correctly in your Environment.
    static let host = Environment.baseURL
    
    case createLinkToken
    case exchangePublicToken
    case removeItem
    case transactions
    case summaries
    case aiSummary
    case budget
    
    /// Returns the full URL for the given endpoint.
    var url: URL {
        let path: String
        switch self {
        case .createLinkToken:
            path = "/auth/create_link_token"
        case .exchangePublicToken:
            path = "/auth/exchange_public_token"
        case .removeItem:
            path = "/auth/remove_item"
        case .transactions:
            path = "/transactions"
        case .summaries:
            path = "/summaries"
        case .aiSummary:
            path = "/ai/weekly_summary"
        case .budget:
            path = "/budget"
            
        }
        return URL(string: API.host + path)!
    }
}

