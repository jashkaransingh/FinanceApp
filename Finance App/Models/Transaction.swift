//
//  Transaction.swift
//  Finance App
//
//  Created by Jas  on 5/22/25.
//

import Foundation

struct Transaction: Decodable {
    let name: String
    let amount: Double
    let date: String
    let category: String
}

struct TransactionsResponse: Decodable {
    let transactions: [Transaction]
}
