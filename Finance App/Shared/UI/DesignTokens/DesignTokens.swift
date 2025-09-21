//
//  DesignTokens.swift
//  Finance App
//
//  Created by Jas  on 8/28/25.
//

import UIKit

/// Global design tokens. Read-only, app-wide.
enum Design {
    
    // MARK: - Corner radii (pt)
    enum Radius {
        static let xs: CGFloat = 8      // tiny chips
        static let row: CGFloat = 12    // list rows / cells
        static let button: CGFloat = 16 // primary buttons
        static let card: CGFloat = 20   // cards (your choice)
        static let xl: CGFloat = 24     // big modals/hero
        // Pills use height/2, so no fixed token.
        static let capsule: CGFloat = 16
    }
    static let cornerCurve: CALayerCornerCurve = .continuous
    
    // MARK: - Spacing (pt)
    enum Space {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
    }
    
    // MARK: - Hairline
    enum Hairline {
        static var width: CGFloat { 1.0 / UIScreen.main.scale } // 1px
        static var color: UIColor {
            UIColor { tc in
                tc.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.28)
                : UIColor.black.withAlphaComponent(0.12)
            }
        }
    }
    
    enum Row {
        static let height: CGFloat = 56
    }
    
    
    // MARK: - Opacity / Dimming
    enum Alpha {
        /// The translucency used for GradientBackgroundView across settings screens
        static let gradientBackground: CGFloat = 0.06
    }
    
    enum Glass {
        /// The dimming value for GlassCardView in dark mode
        static let cardDimming: CGFloat = 0.22
    }
    
    // MARK: - Surfaces (dynamic colors)
    enum Surface {
        /// Page background for settings/profile screens
        static let page = UIColor.systemGroupedBackground
        
        /// Card/container fill
        static let card: UIColor = UIColor { tc in
            // Light: soft grouped card; Dark: subtle brightening
            if tc.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.06)
            } else {
                return UIColor.secondarySystemGroupedBackground
            }
        }
        
        /// Row/container fill (can match card; separate in case we tweak later)
        static let row: UIColor = UIColor { tc in
            if tc.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.04)
            } else {
                return UIColor.secondarySystemGroupedBackground
            }
        }
    }
    
    // MARK: - Helpers to apply styles (optional but handy)
    static func applyCardStyle(to view: UIView) {
        view.backgroundColor = Surface.card
        view.layer.cornerRadius = Radius.card
        view.layer.cornerCurve = cornerCurve
    }
    
    static func applyRowStyle(to view: UIView) {
        view.backgroundColor = Surface.row
        view.layer.cornerRadius = Radius.row
        view.layer.cornerCurve = cornerCurve
    }
    
    static func applyHairlineBorder(to view: UIView) {
        view.layer.borderColor = Hairline.color.cgColor
        view.layer.borderWidth = Hairline.width
    }
}

