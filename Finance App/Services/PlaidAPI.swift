//
//  PlaidAPI.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation

enum PlaidAPI {/// Defines all Plaid backend endpoints
    static let host = Environment.baseURL

    case createLinkToken
    case exchangePublicToken
    case removeItem
    case refresh
    case transactions
    case custom(path: String)

    /// Returns full URL for the endpoint
    var url: URL {
        let path: String = {
            switch self {
            case .createLinkToken:      return "/create_link_token"
            case .exchangePublicToken:  return "/exchange_public_token"
            case .removeItem:           return "/remove_item"
            case .refresh:              return "/refresh"
            case .transactions:         return "/transactions"
            case .custom(let p):        return p
            }
        }()
        return URL(string: PlaidAPI.host + path)!
    }
}

