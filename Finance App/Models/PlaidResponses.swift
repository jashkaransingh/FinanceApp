//
//  PlaidResponses.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation

/// Response from POST /create_link_token
struct LinkTokenResponse: Decodable {
    let link_token: String
}

/// Response from POST /exchange_public_token
struct ExchangeTokenResponse: Decodable {
    let access_token: String
}

/// Response from POST /remove_item
struct RemoveItemResponse: Decodable {
    let removed: Bool
}

/// Response from POST /refresh
/// (Adjust the fields here to whatever your backend actually returns.)
struct RefreshResponse: Decodable {
    let success: Bool
}

/// Response from GET /transactions?…
/// (You already handle this with TransactionsResponse, so just keep that.)
struct TransactionsResponse: Decodable {
    let transactions: [Transaction]
}

/// Wrapper for summaries endpoint
struct SummariesResponse: Decodable {//aloow swift to decode JSON into this struct
    let summaries: [AccountSummary]
}

