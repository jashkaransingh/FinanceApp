//
//  AppFormatters.swift
//  Finance App
//
//  Created by Jas  on 9/13/25.
//

import Foundation

enum AppFormatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f
    }()

    static let isoYMD: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static let prettyMDY: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

