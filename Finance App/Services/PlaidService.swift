//
//  PlaidService.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//


import LinkKit
import UIKit
import FirebaseAuth

/// Manages Plaid Link flows and backend exchanges
final class PlaidService {
    static let shared = PlaidService()
    private init() {}
    
    /// Keeps LinkKit handler alive between calls
    var linkHandler: LinkKit.Handler?
    
    /// Starts the Plaid Link flow
    func startPlaidLink(
        from viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (NetworkError) -> Void
    ) {
        // FIX: Use the new, type-safe EmptyBody struct for requests with no body.
        NetworkService.postJSON(
            to: API.createLinkToken.url,
            body: EmptyBody(), // This is now explicit and safe.
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
        onError: @escaping (NetworkError) -> Void
    ) {
        var config = LinkTokenConfiguration(token: token) { linkSuccess in
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


