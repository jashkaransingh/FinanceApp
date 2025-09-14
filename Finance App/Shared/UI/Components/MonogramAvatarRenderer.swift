//
//  MonogramAvatarRenderer.swift
//  Finance App
//
//  Created by Jas  on 8/25/25.
//

import UIKit

struct MonogramAvatarRenderer {

    // Existing function (keep as-is)
    static func image(name: String?, email: String?, size: CGFloat = 56, font: UIFont? = nil) -> UIImage {
        // call the new overload with defaults (hashed bg + white text)
        return image(
            name: name,
            email: email,
            size: size,
            font: font,
            textColor: .white,
            backgroundColor: backgroundColor(for: (name ?? email ?? "user"))
        )
    }

    // NEW: lets you pick text & background colors
    static func image(name: String?,
                      email: String?,
                      size: CGFloat,
                      font: UIFont?,
                      textColor: UIColor,
                      backgroundColor: UIColor) -> UIImage {
        let initials = makeInitials(name: name, email: email)
        let fnt = font ?? UIFont.systemFont(ofSize: size * 0.42, weight: .semibold)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            // Background circle
            backgroundColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: size / 2).fill()
            // Centered initials
            let attrs: [NSAttributedString.Key: Any] = [
                .font: fnt,
                .foregroundColor: textColor
            ]
            let textSize = initials.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            initials.draw(in: textRect, withAttributes: attrs)
        }
    }

    // MARK: - Helpers (unchanged)
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


