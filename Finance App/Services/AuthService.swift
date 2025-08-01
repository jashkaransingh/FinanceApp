//
//  AuthService.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

class AuthService {
    
    public enum AuthError: Error {
        case userNotFound         // login: no account with that email
        case wrongPassword        // login: password was incorrect
        case emailAlreadyInUse    // signup: account already exists
        case weakPassword         // signup: password fails strength rules
        case networkError         // underlying network request failed
        case profileSaveFailed(Error)
        case unknown(String)      // catch‑all for other error messages
    }
    
    static func signIn(email: String,
                       password: String,
                       completion: @escaping (Result<Void, AuthError>) -> Void) {
        // Note the fully‑qualified FirebaseAuth.Auth.auth()
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            // If Firebase gave us back an error, map it to AuthError
            if let nsError = error as NSError? {
                let authErr: AuthError
                switch nsError.code {
                case AuthErrorCode.userNotFound.rawValue:
                    authErr = .userNotFound
                case AuthErrorCode.wrongPassword.rawValue:
                    authErr = .wrongPassword
                case AuthErrorCode.networkError.rawValue:
                    authErr = .networkError
                default:
                    authErr = .unknown(nsError.localizedDescription)
                }
                completion(.failure(authErr))
            } else {
                // no error → success
                completion(.success(()))
            }
        }
    }
    
    
    
    static func register(email: String,
                         password: String,
                         name: String,
                         completion: @escaping (Result<Void, AuthError>) -> Void) {
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { result, error in
            // If Firebase returned an error, map to AuthError:
            if let nsError = error as NSError? {
                let authErr: AuthError
                switch nsError.code {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    authErr = .emailAlreadyInUse
                case AuthErrorCode.weakPassword.rawValue:
                    authErr = .weakPassword
                case AuthErrorCode.networkError.rawValue:
                    authErr = .networkError
                default:
                    authErr = .unknown(nsError.localizedDescription)
                }
                completion(.failure(authErr))
                return
            }
            
            // We got a new user object
            guard let user = result?.user else {
                completion(.failure(.unknown("Could not retrieve created user")))
                return
            }
            
            // Save their profile in Firestore, then forward that result
            saveUserProfile(user: user, name: name, email: email) { saveResult in
                switch saveResult {
                case .success:
                    // Profile write succeeded → done.
                    completion(.success(()))
                    
                case .failure(let saveError):
                    // Profile write failed → delete the just‐created Auth user to avoid a “ghost” account
                    if let createdUser = Auth.auth().currentUser {
                        createdUser.delete { _ in
                            // Even if delete itself errors, bubble up the original saveError
                            completion(.failure(saveError))
                        }
                    } else {
                        // No currentUser? Just forward the profile‐save error
                        completion(.failure(saveError))
                    }
                }
            }
        }
    }
    
    
    
    static func signOut() {
        try? Auth.auth().signOut()
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
    static func signInWithApple(
        credential: ASAuthorizationAppleIDCredential,
        nonce: String?,
        completion: @escaping (Result<Void, AuthError>) -> Void
    ) {
        // 1) Extract the ID token string
        guard
            let appleIDToken = credential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            completion(.failure(.unknown("Invalid Apple credential")))
            return
        }
        
        // 2) Build the Firebase credential
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        // 3) Sign in with Firebase
        FirebaseAuth.Auth.auth().signIn(with: firebaseCredential) { authResult, error in
            // Error path: map NSError → AuthError
            if let nsError = error as NSError? {
                let authErr: AuthError
                switch nsError.code {
                case AuthErrorCode.invalidCredential.rawValue:
                    authErr = .unknown("Invalid Apple credential")
                case AuthErrorCode.networkError.rawValue:
                    authErr = .networkError
                default:
                    authErr = .unknown(nsError.localizedDescription)
                }
                completion(.failure(authErr))
                return
            }
            
            // Success path: new user? save profile, else just complete
            guard let result = authResult else {
                completion(.failure(.unknown("No auth result")))
                return
            }
            
            if result.additionalUserInfo?.isNewUser == true {
                let name = credential.fullName?.givenName ?? "User"
                let email = credential.email ?? ""
                saveUserProfile(user: result.user, name: name, email: email) { saveResult in
                    // forward the saveResult (which is Result<Void,AuthError>)
                    completion(saveResult)
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Signs the user into Firebase using a Google ID token.
    static func signInWithGoogle(
        idToken: String,
        completion: @escaping (Result<Void, AuthError>) -> Void
    ) {
        let firebaseCredential = GoogleAuthProvider
            .credential(withIDToken: idToken, accessToken: "")
        
        FirebaseAuth.Auth.auth().signIn(with: firebaseCredential) { authResult, error in
            // Error path
            if let nsError = error as NSError? {
                let authErr: AuthError
                switch nsError.code {
                case AuthErrorCode.networkError.rawValue:
                    authErr = .networkError
                default:
                    authErr = .unknown(nsError.localizedDescription)
                }
                completion(.failure(authErr))
                return
            }
            
            // Success: new user? save profile, else complete
            guard let result = authResult else {
                completion(.failure(.unknown("No auth result")))
                return
            }
            
            if result.additionalUserInfo?.isNewUser == true {
                let name = result.user.displayName ?? "User"
                let email = result.user.email ?? ""
                saveUserProfile(user: result.user, name: name, email: email) { saveResult in
                    completion(saveResult)
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Private Helper
    
    private static func saveUserProfile(user: User,
                                        name: String,
                                        email: String,
                                        completion: @escaping (Result<Void, AuthError>) -> Void) {
        // 1. Create an instance of our new Codable struct.
        let userProfile = UserProfile(name: name,
                                      email: email,
                                      createdAt: Timestamp(),
                                      isBankConnected: false,
                                      accountSummaries: nil)
        
        let db = Firestore.firestore()
        
        do {
            // 2. Use the modern setData(from:) method to save the struct.
            try db.collection("users")
                .document(user.uid)
                .setData(from: userProfile) { error in
                    if let error = error {
                        // We use the more specific error we created earlier!
                        completion(.failure(.profileSaveFailed(error)))
                    } else {
                        completion(.success(()))
                    }
                }
        } catch {
            // This catches errors if the userProfile object can't be encoded.
            completion(.failure(.unknown("Could not encode user profile: \(error)")))
        }
    }
}

