//
//  SharedModels.swift
//  Finance App
//
//  Created by Jas  on 8/7/25.
//

import Foundation

/// Exactly matches what your app writes into the JSON file.
struct SharedBudgetData: Codable {
    let today: Double
    let yesterday: Double
    let weeklyBudget: Double
}

