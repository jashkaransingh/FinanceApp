//
//  SummaryEntry.swift
//  Finance App
//
//  Created by Jas  on 6/2/25.
//

import Foundation

struct SummaryEntry: Codable, Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let subtitle: String

    // By excluding 'id' from the CodingKeys, you tell the JSONDecoder
    // to ignore it, which removes the warning and makes your intent clear.
    private enum CodingKeys: String, CodingKey {
        case title, amount, subtitle
    }
}

