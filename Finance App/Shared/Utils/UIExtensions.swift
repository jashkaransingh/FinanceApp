//
//  UIExtensions.swift
//  Finance App
//
//  Created by Jas  on 12/25/25.
//

import UIKit

extension UITextField {
    func addDoneToolbar() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(resignFirstResponder))
        toolbar.items = [flexSpace, doneButton]
        toolbar.sizeToFit()
        inputAccessoryView = toolbar
    }

    var trimmedText: String {
        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
extension UIView {
    func allSubviewsRecursive() -> [UIView] {
        subviews + subviews.flatMap { $0.allSubviewsRecursive() }
    }
}

