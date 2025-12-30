//
//  LegalTextViewController.swift
//  Finance App
//
//  Created by Jas  on 8/25/25.
//

import UIKit

// MARK: - LegalDocument Enum

enum LegalDocument: String {
    case terms   = "TermsOfUse"
    case privacy = "PrivacyPolicy"
    
    var title: String {
        switch self {
        case .terms:   return "Terms of Service"
        case .privacy: return "Privacy Policy"
        }
    }
}

// MARK: - LegalTextViewController

final class LegalTextViewController: UIViewController {
    
    // MARK: - Properties
    
    private let document: LegalDocument
    private let textView = UITextView()
    private var hasScrolledToTop = false
    
    // MARK: - Initialization
    
    init(document: LegalDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        self.title = document.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        configureTextView()
        renderMarkdown()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasScrolledToTop {
            textView.contentOffset = .zero
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasScrolledToTop {
            textView.contentOffset = .zero
            hasScrolledToTop = true
        }
    }
    
    // MARK: - UI Configuration
    
    private func configureTextView() {
        textView.isEditable = false
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 32, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = [.link, .phoneNumber]
        textView.linkTextAttributes = [.foregroundColor: UIColor.link]
        textView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Markdown Rendering
    
    private func renderMarkdown() {
        guard
            let url = Bundle.main.url(forResource: document.rawValue, withExtension: "md"),
            var md  = try? String(contentsOf: url, encoding: .utf8)
        else {
            showErrorState()
            return
        }
        
        // Normalize newlines
        md = md.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        if #available(iOS 15.0, *) {
            renderAttributedMarkdown(md)
        } else {
            renderPlainText(md)
        }
    }
    
    @available(iOS 15.0, *)
    private func renderAttributedMarkdown(_ markdown: String) {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        
        guard let attributedString = try? AttributedString(markdown: markdown, options: options) else {
            renderPlainText(markdown)
            return
        }
        
        let mutable = NSMutableAttributedString(attributedString)
        applyTextFormatting(to: mutable)
        
        textView.attributedText = mutable
        
        // Reset scroll position after attributed text is set
        DispatchQueue.main.async { [weak self] in
            self?.textView.contentOffset = .zero
            self?.textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
    }
    
    private func renderPlainText(_ text: String) {
        textView.text = text
        textView.font = .preferredFont(forTextStyle: .body)
        
        DispatchQueue.main.async { [weak self] in
            self?.textView.contentOffset = .zero
        }
    }
    
    private func applyTextFormatting(to attributedString: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: attributedString.length)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        paragraphStyle.paragraphSpacing = 8
        
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
    }
    
    private func showErrorState() {
        textView.text = "Missing \(document.title) file."
        textView.font = .preferredFont(forTextStyle: .body)
    }
}
