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

/// A simple error type for Plaid failures
enum PlaidError: Error {
  case network(Error)
  case parsing
  case plaidSDK(Error)
  case missingAccessToken
}

/// A singleton to manage all your Plaid–backend interactions
final class PlaidService {
  static let shared = PlaidService()
  private init() {}

  // Keep a reference so the Link UI stays alive
  private var linkHandler: Handler?

  // Your backend base URL
    private let baseURL = URL(string: "http://localhost:5050")!

  /// 1️⃣ Create a link token
  func createLinkToken(completion: @escaping (Result<String, PlaidError>) -> Void) {
    let url = baseURL.appendingPathComponent("create_link_token")
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: [:])

    URLSession.shared.dataTask(with: req) { data, _, err in
      if let e = err { return completion(.failure(.network(e))) }
      guard
        let d = data,
        let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
        let token = json["link_token"] as? String
      else { return completion(.failure(.parsing)) }

      completion(.success(token))
    }
    .resume()
  }

  /// 2️⃣ Launch Plaid Link UI, then exchange the public token
  func startPlaidLink(from vc: UIViewController,
                      onSuccess: @escaping () -> Void,
                      onError: @escaping (Error) -> Void)
  {
    createLinkToken { result in
      switch result {
      case .failure(let e):
        onError(e)

      case .success(let linkToken):
        DispatchQueue.main.async {
          let config = LinkTokenConfiguration(token: linkToken) { linkSuccess in
            // once the user has linked, swap the public token
            self.exchangePublicToken(linkSuccess.publicToken) { exchangeResult in
              switch exchangeResult {
              case .success:
                onSuccess()
              case .failure(let e):
                onError(e)
              }
            }
          }

          switch Plaid.create(config) {
          case .failure(let e):
            onError(PlaidError.plaidSDK(e))
          case .success(let handler):
            self.linkHandler = handler
            handler.open(presentUsing: .viewController(vc))
          }
        }
      }
    }
  }

    /// 3️⃣ Exchange that public_token for a long-lived access_token
      ///     → As soon as we get `accessToken`, we write it into Firestore under `users/{uid}`.
      private func exchangePublicToken(_ publicToken: String,
                                       completion: @escaping (Result<String, PlaidError>) -> Void)
      {
        let url = baseURL.appendingPathComponent("exchange_public_token")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["public_token": publicToken])

        URLSession.shared.dataTask(with: req) { data, _, err in
          if let e = err { return completion(.failure(.network(e))) }
          guard
            let d = data,
            let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
            let accessToken = json["access_token"] as? String
          else { return completion(.failure(.parsing)) }

          // ① Persist to UserDefaults (so your view controllers can read it immediately)
          UserDefaults.standard.set(accessToken, forKey: "plaidAccessToken")

          // ② ALSO write it into Firestore under this user’s document
          if let uid = Auth.auth().currentUser?.uid {
            let docRef = Firestore.firestore().collection("users").document(uid)
            docRef.updateData([
              "bankAccessToken": accessToken
            ]) { error in
              if let error = error {
                print("🔥 Failed to save bankAccessToken in Firestore:", error)
                // (You could call completion(.failure(.network(error))) if you want to treat
                //  a Firestore‐write‐failure as a full failure. But usually we let the UI proceed
                //  and “hope” Firestore works. Up to you.)
              }
              completion(.success(accessToken))
            }
          } else {
            // No logged‐in user? Strange, but at least call success so the app can proceed.
            completion(.success(accessToken))
          }
        }
        .resume()
      }

  /// 4️⃣ Optional: Remove (unlink) an Item
    func removeItem(accessToken: String,
                    completion: @escaping (Result<Bool, PlaidError>) -> Void)
    {
      guard let uid = Auth.auth().currentUser?.uid else {
        return completion(.failure(.missingAccessToken))
      }

      let url = baseURL.appendingPathComponent("remove_item")
      var req = URLRequest(url: url)
      req.httpMethod = "POST"
      req.setValue("application/json", forHTTPHeaderField: "Content-Type")

      // Include both the Plaid token and the Firebase UID in the request body
      let body: [String:Any] = [
        "access_token": accessToken,
        "uid": uid
      ]
      req.httpBody = try? JSONSerialization.data(withJSONObject: body)

      URLSession.shared.dataTask(with: req) { data, _, err in
        if let e = err { return completion(.failure(.network(e))) }
        guard
          let d = data,
          let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
          let removed = json["removed"] as? Bool
        else {
          return completion(.failure(.parsing))
        }

        if removed {
          // If removal succeeded (or was already removed), clear UserDefaults
          UserDefaults.standard.removeObject(forKey: "plaidAccessToken")
        }
        completion(.success(removed))
      }
      .resume()
    }


    // 4️⃣ Refresh (optional) – unchanged
      func refreshTransactions(_ accessToken: String,
                               completion: ((Result<Bool, PlaidError>) -> Void)? = nil)
      {
        let url = baseURL.appendingPathComponent("refresh")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["access_token": accessToken])

        URLSession.shared.dataTask(with: req) { data, _, err in
          if let err = err {
            completion?(.failure(.network(err)))
          } else {
            completion?(.success(true))
          }
        }.resume()
      }

      // 5️⃣ Fetch transactions – unchanged
      func fetchTransactions(
        _ accessToken: String,
        completion: @escaping (Result<[[String:Any]], PlaidError>) -> Void
      ) {
        var comps = URLComponents(
          url: baseURL.appendingPathComponent("transactions"),
          resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
          URLQueryItem(name: "access_token", value: accessToken)
        ]
        guard let url = comps.url else {
          return completion(.failure(.parsing))
        }

        URLSession.shared.dataTask(with: url) { data, _, err in
          if let e = err { return completion(.failure(.network(e))) }
          guard
            let d = data,
            let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
            let txns = json["transactions"] as? [[String:Any]]
          else {
            return completion(.failure(.parsing))
          }
          DispatchQueue.main.async { completion(.success(txns)) }
        }
        .resume()
      }
    }

