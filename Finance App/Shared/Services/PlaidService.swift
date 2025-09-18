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
    
    // MARK: - Public API
    
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
            case .failure(let err):
                // Forward upstream (UI layer may present the error)
                dispatchToMain { onError(err) }
                
            case .success(let response):
                // Present Plaid Link UI now that we have a link_token
                self.presentLinkUI(
                    token: response.link_token,
                    from: viewController,
                    onSuccess: { linkSuccess in
                        // 1 Extract institution & compute display name
                        let institution = linkSuccess.metadata.institution
                        
#if DEBUG
                        print("Plaid institution id=\(institution.id) name=\(institution.name)")
#endif
                        
                        let bankNameToSave = BankDisplayNameManager.shared.displayName(for: institution)
                        
                        // 2 Save connected flag + bank name to Firestore
                        guard let uid = Auth.auth().currentUser?.uid else {
                            // No signed-in user; still report success for the Link flow
                            dispatchToMain { onSuccess(linkSuccess) }
                            return
                        }
                        
                        let docRef = Firestore.firestore().collection("users").document(uid)
                        docRef.setData([
                            "isBankConnected": true,
                            "bankName": bankNameToSave
                        ], merge: true) { error in
#if DEBUG
                            if let error = error {
                                print("Firestore error saving bank name: \(error.localizedDescription)")
                            } else {
                                print("Firestore saved bank name: '\(bankNameToSave)'")
                            }
#endif
                            
                            // 3 Notify caller after Firestore write completes
                            dispatchToMain { onSuccess(linkSuccess) }
                        }
                    },
                    onError: { err in
                        dispatchToMain { onError(err) }
                    }
                )
            }
        }
    }
    
    /// Tells the backend to securely unlink the user's account.
    func unlinkAccount(completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        NetworkService.postJSON(
            to: API.removeItem.url,
            body: EmptyBody(),
            decodeTo: GenericSuccessResponse.self
        ) { result in
            completion(result.map { $0.success })
        }
    }
    
    // MARK: - Private
    
    /// Presents the Plaid Link UI with the given token.
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
                    dispatchToMain { onSuccess(linkSuccess) }
                case .failure(let err):
                    dispatchToMain { onError(err) }
                }
            }
        }
        
        config.onExit = { exit in
            if let e = exit.error {
                dispatchToMain { onError(.unknown(e)) }
            }
            // Release the handler once Link UI is dismissed
            self.linkHandler = nil
        }
        
        switch Plaid.create(config) {
        case .failure(let err):
            dispatchToMain { onError(.unknown(err)) }
            
        case .success(let handler):
            self.linkHandler = handler
            // Present UI on main to avoid UIKit warnings
            dispatchToMain {
                handler.open(presentUsing: .viewController(viewController))
            }
        }
    }
    
    /// Sends the public token to the backend to be exchanged and stored securely.
    private func exchangePublicTokenOnBackend(
        _ publicToken: String,
        completion: @escaping (Result<Bool, NetworkError>) -> Void
    ) {
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

// MARK: - App Notifications

extension Notification.Name {
    static let bankAccountLinked   = Notification.Name("bankAccountLinked")
    static let bankAccountUnlinked = Notification.Name("bankAccountUnlinked")
}

// MARK: - Small util

/// Ensure UI callbacks run on the main queue.
private func dispatchToMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread { work() } else { DispatchQueue.main.async { work() } }
}


