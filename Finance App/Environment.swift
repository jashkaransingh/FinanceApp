//
//  Environment.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//
import Foundation

enum Environment {
    static var baseURL: String {
#if DEBUG
        // Local development server
        return "http://127.0.0.1:5050"
#else
        // Production server
        return "https://financeapp-9wxw.onrender.com"
#endif
    }
}


