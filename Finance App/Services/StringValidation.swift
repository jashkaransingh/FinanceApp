//
//  StringValidation.swift
//  Finance App
//
//  Created by Jas  on 7/24/25.
//

import Foundation

extension String {
    
    /// Validates email format using a regular expression.
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    /// Validates password based on strength criteria (8+ chars, 1 uppercase, 1 digit).
    func isValidPassword() -> Bool {
      // 1) min length
      if count < 8 { return false }

      // 2) uppercase
      let up = NSPredicate(format: "SELF MATCHES %@", ".*[A-Z]+.*")
      guard up.evaluate(with: self) else { return false }

      // 3) digit
      let digit = NSPredicate(format: "SELF MATCHES %@", ".*\\d+.*")
      guard digit.evaluate(with: self) else { return false }

      // 4) special char (anything not letter or digit)
      let special = NSPredicate(format: "SELF MATCHES %@", ".*[^A-Za-z0-9].*")
      guard special.evaluate(with: self) else { return false }

      return true
    }

}
