//
//  User.swift
//  Finance App
//
//  Created by Jas  on 7/23/25.
//

import Foundation

struct UserData: Codable {
    // This property name "accountSummaries" must exactly match
    // the key you used in your Python backend.
    let accountSummaries: [AccountSummary]?
    
    // You can add other properties from your user document here later,
    // for example: let isBankConnected: Bool?
}
