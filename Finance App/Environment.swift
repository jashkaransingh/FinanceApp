//
//  Environment.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//
import Foundation

// Before
enum Environment {
    static var baseURL: String {
        #if DEBUG
            // This points to your local machine
        return "https://financeapp-9wxw.onrender.com"
        #else
        return "https://financeapp-9wxw.onrender.com"
        #endif
    }
}

