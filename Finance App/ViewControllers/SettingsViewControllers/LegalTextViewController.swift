//
//  LegalTextViewController.swift
//  Finance App
//
//  Created by Jas  on 8/25/25.
//

import UIKit

enum LegalDocument: String {
    case terms   = "TermsOfUse"     // <- your file name
    case privacy = "PrivacyPolicy"

    var title: String {
        switch self {
        case .terms:   return "Terms of Service"
        case .privacy: return "Privacy Policy"
        }
    }
}

final class LegalTextViewController: UIViewController {

    private let document: LegalDocument
    private let textView = UITextView()

    init(document: LegalDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        self.title = document.title
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // UITextView setup
        textView.isEditable = false
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 32, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = [.link, .phoneNumber]
        textView.linkTextAttributes = [.foregroundColor: UIColor.link]
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        renderMarkdown()
    }

    private func renderMarkdown() {
        guard
            let url = Bundle.main.url(forResource: document.rawValue, withExtension: "md"),
            var md  = try? String(contentsOf: url, encoding: .utf8)
        else {
            textView.text = "Missing \(document.title) file."
            textView.font = .preferredFont(forTextStyle: .body)
            return
        }

        // Normalize newlines so paragraphs/headings don’t “jam” together
        md = md.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")

        if #available(iOS 15.0, *) {
            let opts = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)

            if let att = try? AttributedString(markdown: md, options: opts) {
                let mutable = NSMutableAttributedString(att)

                // Comfortable paragraph spacing + line height for readability
                let full = NSRange(location: 0, length: mutable.length)
                let para = NSMutableParagraphStyle()
                para.lineHeightMultiple = 1.12
                para.paragraphSpacing = 8
                mutable.addAttribute(NSAttributedString.Key.paragraphStyle, value: para, range: full)

                // Base font/color (Markdown will still bold/italic/links appropriately)
                mutable.addAttribute(.foregroundColor, value: UIColor.label, range: full)
                textView.attributedText = mutable
                return
            }
        }

        // Fallback (shouldn’t be hit on iOS 15+, but safe)
        textView.text = md
        textView.font = .preferredFont(forTextStyle: .body)
    }
}

// Small helper (used in other files; harmless here if you already have it)
private extension UIFont {
    func with(weight: UIFont.Weight) -> UIFont {
        let d = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: d, size: pointSize)
    }
}



