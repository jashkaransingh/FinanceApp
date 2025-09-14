//
//  UserProfile.swift
//  Finance App
//
//  Created by Jas  on 7/30/25.
//

import Foundation
import FirebaseFirestore


struct UserProfile: Codable {
    @DocumentID var id: String?
    
    let name: String
    let email: String
    let createdAt: Timestamp
    
    // Add these properties from your UserData struct
    let isBankConnected: Bool?
    var bankName: String? 
    let accountSummaries: [AccountSummary]?
}
