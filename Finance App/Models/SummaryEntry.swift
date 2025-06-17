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
}

