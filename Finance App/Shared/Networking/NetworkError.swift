//
//  NetworkError.swift
//  Finance App
//
//  Created by Jas  on 7/21/25.
//

import Foundation

enum NetworkError: Error {
    case badURL
    case sessionExpired
    case decodingError(Error)
    case serverError(message: String)
    case unknown(Error?)
}
