//
//  AuthService.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import Foundation

import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            completion(error == nil)
        }
    }

    static func register(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            guard let user = result?.user, error == nil else {
                completion(false)
                return
            }
//          save user profile in firebase
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "createdAt": Timestamp()
            ]

            Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .setData(userData) { err in
                    completion(err == nil)
                }
        }
    }


    static func signOut() {
      // 1) Sign out of Firebase:
      try? Auth.auth().signOut()
      
      // 2) Remove any lingering Plaid token from UserDefaults
      UserDefaults.standard.removeObject(forKey: "plaidAccessToken")
    }


    static func isSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    static func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            completion(error == nil)
        }
    }

}

