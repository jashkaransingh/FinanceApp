//
//  LegalTextViewController.swift
//  Finance App
//
//  Created by Jas  on 8/25/25.
//

import UIKit

enum LegalDocument: String {
    case terms = "TermsOfUse"
    case privacy = "PrivacyPolicy"

    var title: String {
        switch self {
        case .terms: return "Terms of Use"
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

        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16)
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadMarkdown()
    }

    private func loadMarkdown() {
        guard let url = Bundle.main.url(forResource: document.rawValue, withExtension: "md"),
              let md = try? String(contentsOf: url) else {
            textView.text = "Missing \(document.title) file."
            return
        }
        if #available(iOS 15.0, *) {
            // Render Markdown with Dynamic Type
            if let att = try? AttributedString(markdown: md) {
                textView.attributedText = NSAttributedString(att)
            } else {
                textView.text = md
            }
        } else {
            textView.text = md
        }
    }
}

