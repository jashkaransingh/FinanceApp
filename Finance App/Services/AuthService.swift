//
//  AuthService.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices // Import for Apple Sign-In types

class AuthService {
    
    // --- Existing Methods (Unchanged) ---
    
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
            // Use the new helper to save user data
            saveUserProfile(user: user, name: name, email: email, completion: completion)
        }
    }
    
    static func signOut() {
        try? Auth.auth().signOut()
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
    
    // MARK: - New Social Sign-In Methods
    
    /// Signs the user into Firebase using an Apple ID credential.
    static func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String?, completion: @escaping (Bool) -> Void) {
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("ERROR: Unable to get idTokenString from Apple credential")
            completion(false)
            return
        }
        
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        Auth.auth().signIn(with: firebaseCredential) { authResult, error in
            guard let authResult = authResult, error == nil else {
                print("ERROR: Firebase sign-in with Apple failed. \(error?.localizedDescription ?? "")")
                completion(false)
                return
            }
            
            // Check if this is a new user to save their profile
            if authResult.additionalUserInfo?.isNewUser == true {
                let name = credential.fullName?.givenName ?? "User"
                let email = credential.email ?? ""
                saveUserProfile(user: authResult.user, name: name, email: email, completion: completion)
            } else {
                // Existing user, sign-in successful
                completion(true)
            }
        }
    }
    
    /// Signs the user into Firebase using a Google ID token.
    static func signInWithGoogle(idToken: String, completion: @escaping (Bool) -> Void) {
        let firebaseCredential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: "")
        
        Auth.auth().signIn(with: firebaseCredential) { authResult, error in
            guard let authResult = authResult, error == nil else {
                print("ERROR: Firebase sign-in with Google failed. \(error?.localizedDescription ?? "")")
                completion(false)
                return
            }
            
            // Check if this is a new user to save their profile
            if authResult.additionalUserInfo?.isNewUser == true {
                let name = authResult.user.displayName ?? "User"
                let email = authResult.user.email ?? ""
                saveUserProfile(user: authResult.user, name: name, email: email, completion: completion)
            } else {
                // Existing user, sign-in successful
                completion(true)
            }
        }
    }
    
    // MARK: - Private Helper
    
    /// Saves a new user's profile to the 'users' collection in Firestore.
    private static func saveUserProfile(user: User, name: String, email: String, completion: @escaping (Bool) -> Void) {
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

