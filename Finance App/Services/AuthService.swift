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
        case emailNotVerified
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
            // Map Firebase error → AuthError
            if let nsError = error as NSError? {
                let authErr: AuthError
                switch nsError.code {
                case AuthErrorCode.emailAlreadyInUse.rawValue: authErr = .emailAlreadyInUse
                case AuthErrorCode.weakPassword.rawValue:      authErr = .weakPassword
                case AuthErrorCode.networkError.rawValue:      authErr = .networkError
                default:                                       authErr = .unknown(nsError.localizedDescription)
                }
                completion(.failure(authErr))
                return
            }

            // Created OK
            guard let user = result?.user else {
                completion(.failure(.unknown("Could not retrieve created user")))
                return
            }

            // 1) Put the name on the FirebaseAuth user (and refresh the cache)
            updateAuthDisplayName(user, to: name) { nameErr in
                if let nameErr = nameErr {
                    // keep strong consistency: remove the auth user on failure
                    user.delete { _ in completion(.failure(.profileSaveFailed(nameErr))) }
                    return
                }

                // 2) Save to Firestore (your existing profile doc)
                saveUserProfile(user: user, name: name, email: email) { saveResult in
                    switch saveResult {
                    case .failure(let saveError):
                        user.delete { _ in completion(.failure(saveError)) }

                    case .success:
                        // 3) Fire a verification email. We DO NOT fail the flow if this send errs.
                        //    We’ll let the verify screen handle resend.
                        sendVerificationEmail { _ in
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }

    /// Sends a verify-email to the *current* user.
    static func sendVerificationEmail(completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(.unknown("No signed-in user")))
            return
        }

        // You can pass ActionCodeSettings to bring users back to your app later.
        // Keeping it simple: let Firebase use the default template & URL.
        user.sendEmailVerification { error in
            if let err = error as NSError? {
                switch err.code {
                case AuthErrorCode.networkError.rawValue: completion(.failure(.networkError))
                case AuthErrorCode.tooManyRequests.rawValue: completion(.failure(.unknown("Too many attempts. Try later.")))
                default: completion(.failure(.unknown(err.localizedDescription)))
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    static func signOut() {
        try? Auth.auth().signOut()
    }
    
    static func isSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    static func resetPassword(email: String,
                              completion: @escaping (Result<Void, AuthError>) -> Void) {
        let auth = Auth.auth()
        
        // Localize Firebase’s email template to the user’s language.
        auth.languageCode = Locale.preferredLanguages.first
        
        // If you later add Dynamic Links, swap to the ActionCodeSettings version below.
        auth.sendPasswordReset(withEmail: email) { error in
            if let err = error as NSError? {
                completion(.failure(mapFirebaseError(err)))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private static func mapFirebaseError(_ nsError: NSError) -> AuthError {
        switch nsError.code {
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        case AuthErrorCode.tooManyRequests.rawValue:
            return .unknown("Too many attempts. Try later.")
        case AuthErrorCode.invalidEmail.rawValue,
             AuthErrorCode.userNotFound.rawValue,
             AuthErrorCode.invalidRecipientEmail.rawValue:
            // We’ll still show a generic “Email sent” in the UI to avoid enumeration,
            // but mapping to a concrete case can help with logging/metrics.
            return .userNotFound
        default:
            return .unknown(nsError.localizedDescription)
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
                let name = credential.fullName?.formatted() ?? "User"
                let email = credential.email ?? result.user.email ?? ""

                updateAuthDisplayName(result.user, to: name) { _ in
                    saveUserProfile(user: result.user, name: name, email: email) { saveResult in
                        completion(saveResult)
                    }
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

                updateAuthDisplayName(result.user, to: name) { _ in
                    saveUserProfile(user: result.user, name: name, email: email) { saveResult in
                        completion(saveResult)
                    }
                }
            } else {
                completion(.success(()))
            }

        }
    }
    
    private static func updateAuthDisplayName(_ user: User,
                                              to name: String,
                                              completion: @escaping (Error?) -> Void) {
        let change = user.createProfileChangeRequest()
        change.displayName = name
        change.commitChanges { err in
            if let err = err { completion(err); return }
            // Make sure the currentUser cache has the new name
            user.reload { _ in completion(nil) }
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

