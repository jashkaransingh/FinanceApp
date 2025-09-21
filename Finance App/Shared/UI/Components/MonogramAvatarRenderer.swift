//
//  MonogramAvatarRenderer.swift
//  Finance App
//
//  Created by Jas  on 8/25/25.
//

import UIKit

/// Renders circular monogram avatars (initials) with a hashed background color.
/// Use the simple `image(name:email:size:font:)` unless you need custom colors.
struct MonogramAvatarRenderer {
    
    // MARK: - Public API
    
    /// Convenience: hashed background, white text.
    static func image(
        name: String?,
        email: String?,
        size: CGFloat = 56,
        font: UIFont? = nil
    ) -> UIImage {
        image(
            name: name,
            email: email,
            size: size,
            font: font,
            textColor: .white,
            backgroundColor: backgroundColor(for: (name ?? email ?? "user"))
        )
    }
    
    /// Full control over text & background colors.
    static func image(
        name: String?,
        email: String?,
        size: CGFloat,
        font: UIFont?,
        textColor: UIColor,
        backgroundColor: UIColor
    ) -> UIImage {
        let initials = makeInitials(name: name, email: email)
        let fnt = font ?? UIFont.systemFont(ofSize: size * 0.42, weight: .semibold)
        let diameter = max(size, 1)
        let rect = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))
        
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { _ in
            // Background circle
            backgroundColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: diameter / 2).fill()
            
            // Centered initials
            let attrs: [NSAttributedString.Key: Any] = [
                .font: fnt,
                .foregroundColor: textColor
            ]
            let textSize = initials.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (diameter - textSize.width)  / 2,
                y: (diameter - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            initials.draw(in: textRect, withAttributes: attrs)
        }
    }
    
    // MARK: - Helpers
    
    private static func makeInitials(name: String?, email: String?) -> String {
        if let n = name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
            let parts = n.split(separator: " ").filter { !$0.isEmpty }
            if let first = parts.first?.first {
                if let last = parts.dropFirst().first?.first {
                    return String([Character(first.uppercased()), Character(last.uppercased())])
                }
                return String(first).uppercased()
            }
        }
        if let e = email?.trimmingCharacters(in: .whitespacesAndNewlines), let c = e.first {
            return String(c).uppercased()
        }
        return "?"
    }
    
    private static func backgroundColor(for key: String) -> UIColor {
        var hasher = Hasher()
        hasher.combine(key.lowercased())
        let hash = hasher.finalize()
        let hue = CGFloat(abs(hash % 360)) / 360.0
        return UIColor(hue: hue, saturation: 0.55, brightness: 0.88, alpha: 1.0)
    }
}



