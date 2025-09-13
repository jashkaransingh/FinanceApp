//
//  PasswordRules.swift
//  Finance App
//
//  Created by Jas  on 9/8/25.
//

import Foundation

public struct PasswordRule {
    public let label: String
    public let passed: Bool
}

public enum PasswordRules {
    public static let minLength = 8

    /// Evaluates the password once for both UI checklist and gating.
    public static func evaluate(_ pw: String) -> (valid: Bool, checks: [PasswordRule]) {
        let lengthOK = pw.count >= minLength
        let upperOK  = pw.range(of: "[A-Z]", options: .regularExpression) != nil
        let digitOK  = pw.range(of: "\\d", options: .regularExpression) != nil
        let specialOK = pw.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil

        let checks: [PasswordRule] = [
            .init(label: "\(minLength)+ characters", passed: lengthOK),
            .init(label: "1 uppercase",              passed: upperOK),
            .init(label: "1 number",                 passed: digitOK),
            .init(label: "1 special character",      passed: specialOK)
        ]

        return (checks.allSatisfy { $0.passed }, checks)
    }
}

