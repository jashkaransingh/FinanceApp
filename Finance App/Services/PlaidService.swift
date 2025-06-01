//
//  PlaidService.swift
//  Finance App
//
//  Created by Jas  on 5/30/25.
//


import Foundation
import LinkKit
import UIKit

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
  private let baseURL = URL(string: "http://192.168.0.87:5050")!

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

      // Persist for your app
      UserDefaults.standard.set(accessToken, forKey: "plaidAccessToken")
      completion(.success(accessToken))
    }
    .resume()
  }

  /// 4️⃣ Optional: Remove (unlink) an Item
  func removeItem(accessToken: String,
                  completion: @escaping (Result<Bool, PlaidError>) -> Void)
  {
    let url = baseURL.appendingPathComponent("remove_item")
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["access_token": accessToken])

    URLSession.shared.dataTask(with: req) { data, _, err in
      if let e = err { return completion(.failure(.network(e))) }
      guard
        let d = data,
        let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
        let removed = json["removed"] as? Bool
      else { return completion(.failure(.parsing)) }

      if removed {
        UserDefaults.standard.removeObject(forKey: "plaidAccessToken")
      }
      completion(.success(removed))
    }
    .resume()
  }

    // 4️⃣ Refresh (optional) – move your refreshTransactions here
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

    // 5️⃣ Fetch transactions – move your fetchTransactions here
    func fetchTransactions(
      _ accessToken: String,
      completion: @escaping (Result<[[String:Any]], PlaidError>) -> Void
    ) {
      // 1) build a URLComponents from your base + path
      var comps = URLComponents(
        url: baseURL.appendingPathComponent("transactions"),
        resolvingAgainstBaseURL: false
      )!
      
      // 2) add the access_token query
      comps.queryItems = [
        URLQueryItem(name: "access_token", value: accessToken)
      ]
      
      // 3) unwrap the resulting URL
      guard let url = comps.url else {
        return completion(.failure(.parsing))
      }
      
      // 4) kick off the request as before
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

