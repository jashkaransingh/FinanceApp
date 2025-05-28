//
//  CustomTextField.swift
//  Finance App
//
//  Created by Jas  on 5/26/25.
//

import UIKit

class CustomTextField: UITextField {
    init(placeholder: String, isSecure: Bool = false) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.isSecureTextEntry = isSecure
        self.borderStyle = .none
        self.layer.cornerRadius = 10
        self.backgroundColor = .secondarySystemGroupedBackground
        self.setLeftPaddingPoints(10)
        self.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        if placeholder.lowercased().contains("email") {
                    self.keyboardType = .emailAddress
                    self.autocapitalizationType = .none
                    self.autocorrectionType = .no
                }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
