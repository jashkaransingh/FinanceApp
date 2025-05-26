//
//  AccountSummary.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import Foundation
// Models/AccountSummary.swift
struct AccountSummary: Decodable {
    let periodTitle: String      // e.g. "Spent Today"
    let amount: Double           // e.g. 64.30
    let percentage: Double       // e.g. -11 (negative = down)
    let subtitle: String         // e.g. "Yesterday $72.50"
    let usesPieIcon: Bool        // true for “This Month”
}

struct SummariesResponse: Decodable {//aloow swift to decode JSON into this struct
    let summaries: [AccountSummary]
}
