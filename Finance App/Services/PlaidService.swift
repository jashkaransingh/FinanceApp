//
//  PlaidService.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//


import LinkKit
import UIKit
import FirebaseAuth
import FirebaseFirestore

/// Manages Plaid Link flows and backend exchanges
final class PlaidService {
    static let shared = PlaidService()
    private init() {}
    
    /// Keeps LinkKit handler alive between calls
    var linkHandler: LinkKit.Handler?
    
    func startPlaidLink(
        from viewController: UIViewController,
        onSuccess: @escaping (LinkSuccess) -> Void,
        onError:   @escaping (NetworkError) -> Void
    ) {
        NetworkService.postJSON(
            to: API.createLinkToken.url,
            body: EmptyBody(),
            decodeTo: LinkTokenResponse.self
        ) { result in
            switch result {
                
                // ───────────────────────
            case .failure(let err):
                // Propagate network errors
                onError(err)
                
                // ───────────────────────
            case .success(let response):
                // Present Plaid Link UI now that we have a link_token
                self.presentLinkUI(
                    token: response.link_token,
                    from: viewController,
                    
                    // This onSuccess gives us the full LinkSuccess object:
                    onSuccess: { (linkSuccess: LinkSuccess) in
                        // ① Extract the institution and get the clean name
                        let institution = linkSuccess.metadata.institution
                        print("CRITICAL DEBUG: The REAL institution ID is '\(institution.id)' and the name is '\(institution.name)'")

                            let bankNameToSave = BankDisplayNameManager.shared.displayName(for: institution)
                            print("DEBUG: Saving this name to Firestore: '\(bankNameToSave)'")

                        // ② Save connected + name to Firestore
                        guard let uid = Auth.auth().currentUser?.uid else {
                            // If there's no user, we can't save. Just call success.
                            onSuccess(linkSuccess)
                            return
                        }

                        let docRef = Firestore.firestore().collection("users").document(uid)
                        
                        docRef.setData([
                            "isBankConnected": true,
                            "bankName": bankNameToSave
                        ], merge: true) { error in
                            // --- THIS IS THE FIX ---
                            // This completion block is only called AFTER Firestore confirms the write.
                            // We now call our original onSuccess handler from here.
                            
                            if let error = error {
                                print("Firestore error saving bank name: \(error.localizedDescription)")
                                // Optionally, you could call your original onError handler here
                                // onError(.unknown(error))
                            } else {
                                print("Firestore successfully saved bank name: '\(bankNameToSave)'")
                            }
                            
                            // ③ Notify your caller that the ENTIRE process is finished.
                            // This now happens AFTER the database write is complete.
                            onSuccess(linkSuccess)
                        }
                    },
                    
                    onError: onError
                )
            }
        }
    }
    
    
    
    /// Presents the Plaid Link UI with the given token
    private func presentLinkUI(
        token: String,
        from viewController: UIViewController,
        onSuccess: @escaping (LinkSuccess) -> Void,
        onError: @escaping (NetworkError) -> Void
    ) {
        var config = LinkTokenConfiguration(token: token) { linkSuccess in
            self.exchangePublicTokenOnBackend(linkSuccess.publicToken) { result in
                switch result {
                case .success:
                    onSuccess(linkSuccess) // <-- Call it on success!
                case .failure(let err):
                    onError(err)
                }
            }
        }
        
        config.onExit = { exit in
            if let e = exit.error {
                onError(.unknown(e))
            }
        }
        
        switch Plaid.create(config) {
        case .failure(let err):
            onError(.unknown(err))
        case .success(let handler):
            self.linkHandler = handler
            handler.open(presentUsing: .viewController(viewController))
        }
    }
    
    /// Tells the backend to securely unlink the user's account.
    func unlinkAccount(completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        // FIX: Use the EmptyBody struct here as well.
        NetworkService.postJSON(
            to: API.removeItem.url,
            body: EmptyBody(),
            decodeTo: GenericSuccessResponse.self
        ) { result in
            completion(result.map { $0.success })
        }
    }
    
    /// Sends the public token to the backend to be exchanged and stored securely.
    private func exchangePublicTokenOnBackend(
        _ publicToken: String,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
        // FIX: Use the new, type-safe ExchangeTokenRequest struct.
        let requestBody = ExchangeTokenRequest(publicToken: publicToken)
        
        NetworkService.postJSON(
            to: API.exchangePublicToken.url,
            body: requestBody,
            decodeTo: GenericSuccessResponse.self
        ) { result in
            completion(result.map { $0.success })
        }
    }
}
extension Notification.Name {
    static let bankAccountLinked = Notification.Name("bankAccountLinked")
}
extension Notification.Name {
    static let bankAccountUnlinked = Notification.Name("bankAccountUnlinked")
}


