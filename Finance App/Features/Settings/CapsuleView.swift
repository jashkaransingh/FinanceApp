//
//  CapsuleContainer.swift
//  Finance App
//
//  Created by Jas  on 8/27/25.
//

import UIKit

/// Perfect pill with a hairline, ultra-crisp border and dynamic fill
/// that looks great in light & dark. Corner = height/2 with .continuous curve.
final class CapsuleView: UIView {

    /// MARK: tasteful defaults (replace these two vars)
    static var neutralFill: UIColor {
        UIColor { tc in
            // Light: soft grey card, not pure white.
            // Dark: slightly brighter graphite so it "reads".
            if tc.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.08)  // graphite glow
            } else {
                return UIColor.secondarySystemBackground       // gentle grey
            }
        }
    }

    static var neutralStroke: UIColor {
        UIColor { tc in
            // Stronger hairline so the pill edge is crisp in both modes
            if tc.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.28)
            } else {
                return UIColor.black.withAlphaComponent(0.12)
            }
        }
    }


    // MARK: public styling
    var fillColor: UIColor = CapsuleView.neutralFill { didSet { updateColors() } }
    var strokeColor: UIColor = CapsuleView.neutralStroke { didSet { updateColors() } }
    var lineWidth: CGFloat = 1.0 / UIScreen.main.scale { didSet { setNeedsLayout() } }
    var cornerRadiusOverride: CGFloat? { didSet { setNeedsLayout() } }

    // MARK: impl
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        lineWidth = 2.0 / UIScreen.main.scale
        isOpaque = false
        layer.cornerCurve = .continuous
        layer.masksToBounds = false

        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.clear.cgColor
        shape.contentsScale = UIScreen.main.scale
        shape.lineJoin = .round
        shape.lineCap  = .round
        layer.insertSublayer(shape, at: 0)

        updateColors()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let r = bounds
        let inset = lineWidth / 2.0

        // If not set, default to full pill (height/2)
        let desiredCorner = cornerRadiusOverride ?? (r.height / 2.0)

        // Clamp so the stroke still lands crisply on-pixel
        let corner = max(0, min(desiredCorner, (r.height / 2.0) - inset))

        let path = UIBezierPath(
            roundedRect: r.insetBy(dx: inset, dy: inset),
            cornerRadius: corner
        )
        shape.path = path.cgPath
        shape.lineWidth = lineWidth
        layer.cornerRadius = corner
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if previous?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateColors()
        }
    }

    private func updateColors() {
        shape.fillColor   = fillColor.resolvedColor(with: traitCollection).cgColor
        shape.strokeColor = strokeColor.resolvedColor(with: traitCollection).cgColor
        setNeedsLayout()
    }
}


