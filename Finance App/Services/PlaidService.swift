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
    
    // MARK: – Properties
    
    /// Keeps LinkKit handler alive between calls
    var linkHandler: LinkKit.Handler?
    
    // MARK: – Public Methods
    
    /// Starts the Plaid Link flow
    func startPlaidLink(
        from viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // This now calls your secure /create_link_token endpoint via NetworkService
        NetworkService.postJSON(
            to: API.createLinkToken.url,
            body: [:], // Body is empty, auth is in the header
            decodeTo: LinkTokenResponse.self
        ) { result in
            switch result {
            case .failure(let err):
                onError(err)
            case .success(let response):
                self.presentLinkUI(
                    token: response.link_token,
                    from: viewController,
                    onSuccess: onSuccess,
                    onError: onError
                )
            }
        }
    }
    
    /// Presents the Plaid Link UI with the given token
    private func presentLinkUI(
        token: String,
        from viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        var config = LinkTokenConfiguration(token: token) { linkSuccess in
            // On success, call our new exchange function
            self.exchangePublicTokenOnBackend(linkSuccess.publicToken) { result in
                switch result {
                case .success:
                    onSuccess()
                case .failure(let err):
                    onError(err)
                }
            }
        }
        
        config.onExit = { exit in
            if let e = exit.error {
                onError(e)
            }
        }
        
        // Create and open the handler
        switch Plaid.create(config) {
        case .failure(let err):
            onError(err)
        case .success(let handler):
            self.linkHandler = handler
            handler.open(presentUsing: .viewController(viewController))
        }
    }
    
    // Tells the backend to securely unlink the user's account.
    func unlinkAccount(completion: @escaping (Result<Bool, Error>) -> Void) {
        // We send an empty body because authentication is handled by the
        // Firebase ID Token in the header, which NetworkService adds automatically.
        NetworkService.postJSON(
            to: API.removeItem.url,
            body: [:],
            decodeTo: ItemRemoveResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.removed))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // --- NEW: This function calls our secure backend endpoint ---
    /// Sends the public token to the backend to be exchanged and stored securely.
    private func exchangePublicTokenOnBackend(
        _ publicToken: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let body = ["public_token": publicToken]
        
        // This now calls your secure /exchange_public_token endpoint
        NetworkService.postJSON(
            to: API.exchangePublicToken.url,
            body: body,
            decodeTo: GenericSuccessResponse.self // A simple struct for { "success": true }
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.success))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}


