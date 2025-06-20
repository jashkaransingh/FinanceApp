//
//  ModernSlider.swift
//  Finance App
//
//  Created by Jas  on 6/18/25.
//

import UIKit

class ModernSlider: UISlider {

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
            // 8pt thick track, centered vertically
            return CGRect(
                x: bounds.minX,
                y: bounds.midY - 4,
                width: bounds.width,
                height: 8
            )
        }

}
