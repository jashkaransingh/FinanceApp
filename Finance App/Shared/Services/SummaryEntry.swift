//
//  SummaryEntry.swift
//  Finance App
//
//  Created by Jas  on 6/2/25.
//

import Foundation

// MARK: - Model

struct SummaryEntry: Codable, Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let subtitle: String

    // Exclude 'id' from coding; only encode/decode data fields.
    private enum CodingKeys: String, CodingKey {
        case title, amount, subtitle
    }
}

