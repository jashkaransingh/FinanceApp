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

/// Errors encountered during Plaid operations
enum PlaidError: Error {
    case network(Error)
    case parsing
    case plaidSDK(Error)
    case missingAccessToken
}

/// Manages Plaid Link flows and backend exchanges
final class PlaidService {
    static let shared = PlaidService()
    private init() {}

    // MARK: – Properties

    /// Keeps LinkKit handler alive between calls
    var linkHandler: LinkKit.Handler?

    /// Firestore collection key for user tokens
    private let firestoreKey = "bankAccessToken"

    // MARK: – Public Methods

    /// Starts the Plaid Link flow
    func startPlaidLink(
        from viewController: UIViewController,
        onSuccess: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        fetchLinkToken { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                DispatchQueue.main.async { onError(err) }

            case .success(let token):
                self.presentLinkUI(token: token,
                                   from: viewController,
                                   onSuccess: onSuccess,
                                   onError: onError)
            }
        }
    }

    /// Unlinks an existing Plaid item
    func removeItem(
        accessToken: String,
        completion: @escaping (Result<Bool, PlaidError>) -> Void
    ) {
        guard let uid = currentUID else {
            return completion(.failure(.missingAccessToken))
        }

        let body: [String: Any] = [
            "access_token": accessToken,
            "uid": uid
        ]
        NetworkService.postJSON(to: PlaidAPI.removeItem.url,
                                body: body,
                                decodeTo: RemoveItemResponse.self) { result in
            switch result {
            case .success(let resp):
                if resp.removed {
                    UserDefaults.standard.removeObject(forKey: "plaidAccessToken")
                }
                completion(.success(resp.removed))
            case .failure(let err):
                completion(.failure(.network(err)))
            }
        }
    }

    /// Refreshes transactions on the backend
    func refreshTransactions(
        _ accessToken: String,
        completion: ((Result<Bool, PlaidError>) -> Void)? = nil
    ) {
        let body = ["access_token": accessToken]
        NetworkService.postJSON(to: PlaidAPI.refresh.url,
                                body: body,
                                decodeTo: RefreshResponse.self) { result in
            switch result {
            case .success: completion?(.success(true))
            case .failure(let err): completion?(.failure(.network(err)))
            }
        }
    }

    // MARK: – Convenience

    /// Checks if a valid token is stored locally
    var hasValidAccessToken: Bool {
        currentAccessToken != nil
    }

    /// Retrieves the current token from UserDefaults
    var currentAccessToken: String? {
        let token = UserDefaults.standard.string(forKey: "plaidAccessToken")
        return token?.isEmpty == false ? token : nil
    }

    // MARK: – Private Helpers

    /// Fetches a fresh Link Token from your backend
    private func fetchLinkToken(
        completion: @escaping (Result<String, PlaidError>) -> Void
    ) {
        NetworkService.postJSON(to: PlaidAPI.createLinkToken.url,
                                body: [:],
                                decodeTo: LinkTokenResponse.self) { result in
            switch result {
            case .success(let resp):  completion(.success(resp.link_token))
            case .failure(let err):  completion(.failure(.network(err)))
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
            self.exchangePublicToken(linkSuccess.publicToken, completion: { result in
                switch result {
                case .success: onSuccess()
                case .failure(let err): onError(err)
                }
            })
        }

        // Called when user exits Plaid Link
        config.onExit = { exit in
            if let e = exit.error {
                onError(e)
            } else {
                let cancelErr = NSError(
                    domain: "PlaidService",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User cancelled Link"]
                )
                onError(cancelErr)
            }
        }

        switch Plaid.create(config) {
        case .failure(let err):
            onError(err)
        case .success(let handler):
            linkHandler = handler
            handler.open(presentUsing: .viewController(viewController))
        }
    }

    /// Exchanges a public token for a long-lived access token
    private func exchangePublicToken(
        _ publicToken: String,
        completion: @escaping (Result<String, PlaidError>) -> Void
    ) {
        let body = ["public_token": publicToken]
        NetworkService.postJSON(to: PlaidAPI.exchangePublicToken.url,
                                body: body,
                                decodeTo: ExchangeTokenResponse.self) { result in
            switch result {
            case .success(let resp):
                self.persistAccessToken(resp.access_token)
                completion(.success(resp.access_token))
            case .failure(let err):
                completion(.failure(.network(err)))
            }
        }
    }

    /// Saves token locally and in Firestore
    private func persistAccessToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "plaidAccessToken")

        guard let uid = currentUID else { return }
        let doc = Firestore.firestore().collection("users").document(uid)
        doc.updateData(["bankAccessToken": token]) { error in
            if let e = error {
                print("Firestore save error:", e)
            }
        }
    }

    /// Current authenticated Firebase UID
    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
}

