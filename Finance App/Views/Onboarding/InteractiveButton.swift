//
//  InteractiveButton.swift
//  Finance App
//
//  Created by Jas  on 7/31/25.
//

import UIKit

final class InteractiveButton: UIButton {

    // This property observer automatically triggers when the button is pressed or released.
    override var isHighlighted: Bool {
        didSet {
            // Animate the button's size based on the highlighted state.
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
                self.transform = self.isHighlighted ? .init(scaleX: 0.95, y: 0.95) : .identity
            }, completion: nil)
        }
    }
}
