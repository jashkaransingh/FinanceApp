//
//  VersionInfoViewController.swift
//  Finance App
//
//  Created by Jas  on 8/25/25.
//

import UIKit
import StoreKit
import MessageUI

final class VersionInfoViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: - Config
    private let appStoreID: String? = nil
    private let supportEmail = "support@example.com"
    private let tagline = "Your Personal Finance Companion."
    private let companyName = "Jazz Creations"
    /// Show one or more points under "Version".
    private let releaseNotes: [String] = [
        "Initial release — budgets, expense tracking, and reminders."
    ]
    
    // MARK: - Derived
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Finance App"
    }
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    // MARK: - UI
    private let card: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.directionalLayoutMargins = .init(top: 20, leading: 20, bottom: 18, trailing: 20)
        return v
    }()
    
    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    // Hero
    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 64),
            v.heightAnchor.constraint(equalToConstant: 64)
        ])
        return v
    }()
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.preferredSymbolConfiguration = .init(pointSize: 28, weight: .semibold)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var nameLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.adjustsFontForContentSizeCategory = true
        return l
    }()
    private lazy var versionLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .preferredFont(forTextStyle: .headline).with(weight: .bold)
        l.textColor = .label
        l.adjustsFontForContentSizeCategory = true
        return l
    }()
    private lazy var bulletsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 6
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    private lazy var taglineLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .preferredFont(forTextStyle: .callout)
        l.textColor = .tertiaryLabel
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.setContentHuggingPriority(.required, for: .vertical)
        l.adjustsFontForContentSizeCategory = true
        return l
    }()
    private lazy var footerLabel: UILabel = {
        let year = Calendar.current.component(.year, from: Date())
        let l = UILabel()
        l.textAlignment = .center
        l.font = .preferredFont(forTextStyle: .caption2)
        l.textColor = .quaternaryLabel
        l.adjustsFontForContentSizeCategory = true
        l.text = "© \(year) \(companyName) • All rights reserved."
        return l
    }()
    
    // Tiles
    private lazy var tilesRow: UIStackView = {
        let h = UIStackView(arrangedSubviews: [rateTile, supportTile])
        h.axis = .horizontal
        h.alignment = .fill
        h.distribution = .fillEqually
        h.spacing = 12
        h.translatesAutoresizingMaskIntoConstraints = false
        return h
    }()
    private lazy var rateTile: UIButton    = makeTile(title: "Rate this App",   symbol: "star.fill",     action: #selector(rateApp))
    private lazy var supportTile: UIButton = makeTile(title: "Contact Support", symbol: "envelope.fill", action: #selector(contactSupport))
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        buildUI()
        configureIcon()
        
        // Styled title
        nameLabel.attributedText = styledAppName(appName)
        versionLabel.text = "Version \(version)"
        taglineLabel.text = tagline
        
        // Bullets
        bulletsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        releaseNotes.forEach { bulletsStack.addArrangedSubview(makeBulletRow($0)) }
    }
    
    private func buildUI() {
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            card.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor)
        ])
        
        let iconWrap = UIView()
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconContainer.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: iconWrap.topAnchor),
            iconContainer.bottomAnchor.constraint(equalTo: iconWrap.bottomAnchor),
            
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalTo: iconContainer.widthAnchor, multiplier: 0.62),
            iconView.heightAnchor.constraint(equalTo: iconContainer.heightAnchor, multiplier: 0.62)
        ])
        
        stack.addArrangedSubview(iconWrap)
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(versionLabel)
        stack.addArrangedSubview(bulletsStack)  // directly under Version
        stack.addArrangedSubview(taglineLabel)
        stack.addArrangedSubview(tilesRow)
        stack.addArrangedSubview(footerLabel)
        
        // Rhythm (tight + consistent)
        stack.setCustomSpacing(12, after: iconWrap)     // icon → name
        stack.setCustomSpacing(6,  after: nameLabel)    // name → version
        stack.setCustomSpacing(10, after: versionLabel) // version → bullets
        stack.setCustomSpacing(12, after: bulletsStack) // bullets → tagline
        stack.setCustomSpacing(14, after: taglineLabel) // tagline → tiles
        stack.setCustomSpacing(10, after: tilesRow)     // tiles → footer
    }
    
    // MARK: - Icon
    private func configureIcon() {
        if let appIcon = primaryAppIcon() {
            iconContainer.backgroundColor = .clear
            iconContainer.layer.cornerRadius = 12
            iconContainer.layer.masksToBounds = true
            iconView.image = appIcon
            iconView.tintColor = nil
        } else {
            iconView.image = UIImage(systemName: "building.columns.fill")
        }
    }
    private func primaryAppIcon() -> UIImage? {
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String]
        else { return nil }
        for name in files.reversed() {
            if let img = UIImage(named: name) { return img }
        }
        return nil
    }
    
    // MARK: - Tiles
    private func makeTile(title: String, symbol: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        var cfg = UIButton.Configuration.gray()
        cfg.title = title
        cfg.image = UIImage(systemName: symbol)
        cfg.imagePlacement = .top
        cfg.imagePadding = 6
        cfg.baseForegroundColor = .label
        cfg.background.cornerRadius = 14
        cfg.background.backgroundColor = .tileFill
        cfg.contentInsets = .init(top: 8, leading: 10, bottom: 8, trailing: 10) // smaller
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: 15, weight: .semibold)
        b.configuration = cfg
        b.layer.cornerCurve = .continuous
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }
    
    // MARK: - Exact compact height
    func compactHeight(for sheetWidth: CGFloat) -> CGFloat {
        view.bounds.size.width = sheetWidth
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        let m = view.layoutMargins
        let cardWidth = max(0, sheetWidth - m.left - m.right)
        
        let cardHeight = card.systemLayoutSizeFitting(
            CGSize(width: cardWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        
        let total = 20 + cardHeight + 20
        return ceil(total)
    }
    
    // MARK: - Adapt tiles on appearance change
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else { return }
        [rateTile, supportTile].forEach { b in
            var cfg = b.configuration
            cfg?.background.backgroundColor = .tileFill
            b.configuration = cfg
        }
    }
    
    // MARK: - Actions
    @objc private func rateApp() {
        if let id = appStoreID,
           let url = URL(string: "https://apps.apple.com/app/id\(id)?action=write-review") {
            UIApplication.shared.open(url); return
        }
        if let scene = view.window?.windowScene {
            if #available(iOS 14.0, *) { SKStoreReviewController.requestReview(in: scene) }
            else { SKStoreReviewController.requestReview() }
        }
    }
    
    @objc private func contactSupport() {
        let subject = "[\(appName)] Support"
        let body = """
        Hi \(companyName),
        
        (Tell us what went wrong or what you need help with.)
        
        ––
        App: \(appName) \(version)
        Device: iOS \(UIDevice.current.systemVersion)
        """
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([supportEmail])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else {
            var comps = URLComponents()
            comps.scheme = "mailto"
            comps.path = supportEmail
            comps.queryItems = [
                URLQueryItem(name: "subject", value: subject),
                URLQueryItem(name: "body", value: body)
            ]
            if let url = comps.url { UIApplication.shared.open(url) }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Present compact
extension VersionInfoViewController {
    static func presentCompact(from presenter: UIViewController) {
        let vc = VersionInfoViewController()
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.prefersGrabberVisible = false
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false

            if #available(iOS 16.0, *) {
                let id = UISheetPresentationController.Detent.Identifier("fit")

                let detent = UISheetPresentationController.Detent.custom(identifier: id) { [weak vc] context in
                    guard let vc else { return 300 }

                    // Use the REAL presented width if available
                    let width = vc.view.bounds.width > 0
                        ? vc.view.bounds.width
                        : (presenter.view.bounds.width)

                    let contentH = vc.compactHeight(for: width)

                    // Small breathing room prevents 1px clipping on some devices
                    let padded = contentH + 8

                    return min(padded, context.maximumDetentValue - 12)
                }

                sheet.detents = [detent]
                sheet.selectedDetentIdentifier = id
            } else if #available(iOS 15.0, *) {
                sheet.detents = [.medium()]
                sheet.selectedDetentIdentifier = .medium
            }
        }

        presenter.present(vc, animated: true)
    }
}


// MARK: - Styling helpers
private extension UIFont {
    func with(weight: UIFont.Weight) -> UIFont {
        let d = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: d, size: pointSize)
    }
    static func rounded(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        if let rounded = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: rounded, size: base.pointSize).with(weight: weight)
        }
        return base.with(weight: weight)
    }
}

/// Name: readable + slightly fancy (Avenir Next if present; else SF Rounded) with gentle letter-spacing.
private func styledAppName(_ text: String) -> NSAttributedString {
    let size = UIFont.preferredFont(forTextStyle: .title2).pointSize
    let baseFont: UIFont
    if let avenir = UIFont(name: "AvenirNext-DemiBold", size: size) {
        baseFont = UIFontMetrics(forTextStyle: .title2).scaledFont(for: avenir)
    } else {
        baseFont = UIFont.rounded(forTextStyle: .title2, weight: .semibold)
    }
    return NSAttributedString(string: text, attributes: [.font: baseFont, .kern: 0.6])
}

/// A bullet row with a fixed bullet column so wrapped lines align nicely.
private func makeBulletRow(_ text: String) -> UIStackView {
    let bullet = UILabel()
    bullet.text = "•"
    bullet.textColor = .secondaryLabel
    bullet.font = .preferredFont(forTextStyle: .footnote)
    bullet.setContentHuggingPriority(.required, for: .horizontal)
    bullet.setContentCompressionResistancePriority(.required, for: .horizontal)
    bullet.widthAnchor.constraint(equalToConstant: 12).isActive = true
    
    let body = UILabel()
    body.text = text
    body.numberOfLines = 0
    body.lineBreakMode = .byWordWrapping
    body.textColor = .secondaryLabel
    body.font = .preferredFont(forTextStyle: .footnote)
    body.setContentCompressionResistancePriority(.required, for: .vertical)
    body.setContentHuggingPriority(.required, for: .vertical)
    
    let row = UIStackView(arrangedSubviews: [bullet, body])
    row.axis = .horizontal
    row.alignment = .firstBaseline
    row.spacing = 6
    return row
}

private extension UIColor {
    static var tileFill: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? .secondarySystemFill : .tertiarySystemFill
        }
    }
}
