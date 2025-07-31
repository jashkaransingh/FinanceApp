//
//  UserProfile.swift
//  Finance App
//
//  Created by Jas  on 7/30/25.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable {
    // This special property wrapper tells Firestore to map the document's ID to this property.
    @DocumentID var id: String?
    
    let name: String
    let email: String
    let createdAt: Timestamp
}
