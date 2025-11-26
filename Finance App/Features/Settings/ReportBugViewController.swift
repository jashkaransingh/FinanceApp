//
//  ReportBugViewController.swift
//  Finance App
//
//  Created by Jas  on 9/24/25.
//

import UIKit
import PhotosUI
import MessageUI
import FirebaseAuth

final class ReportBugViewController: UIViewController, MFMailComposeViewControllerDelegate {

    // MARK: - UI
    private let gradientBackground = GradientBackgroundView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Short title (e.g., Crash on Budget AI)"
        tf.font = .systemFont(ofSize: 17, weight: .semibold)
        tf.clearButtonMode = .whileEditing
        tf.returnKeyType = .next
        tf.accessibilityIdentifier = "bug.title"
        return tf
    }()

    private let descriptionView = PlaceholderTextView(
        placeholder: "Describe what happened, steps to reproduce, and what you expected..."
    )

    private let attachButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .large
        config.baseBackgroundColor = .secondarySystemBackground
        config.baseForegroundColor = .label
        config.title = "Attach Screenshot"
        config.image = UIImage(systemName: "photo.fill")
        config.imagePlacement = .leading
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        let b = UIButton(configuration: config)
        b.accessibilityIdentifier = "bug.attach"
        return b
    }()

    private let attachmentsStack = UIStackView()

    private let diagnosticsSwitch = UISwitch()
    private let sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .large
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.title = "Send"
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        let b = UIButton(configuration: config)
        b.accessibilityIdentifier = "bug.send"
        return b
    }()
    private func refreshSendEnabled() {
        let hasContent = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      || !descriptionView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.isEnabled = hasContent
        sendButton.alpha = hasContent ? 1 : 0.6
    }

    private var attachedImages: [UIImage] = [] {
        didSet { reloadAttachments() }
    }
    private var keyboardTokens: [NSObjectProtocol] = []


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report a Bug"
        view.backgroundColor = Design.Surface.page
        setupLayout()
        scrollView.keyboardDismissMode = .interactive
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tapToDismiss.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapToDismiss)
        setupActions()
        refreshSendEnabled()
        setupKeyboardHandling()
    }

    // MARK: - Layout (Glass cards like your Settings screen)
    private func setupLayout() {
        // background
        view.addSubview(gradientBackground)
        gradientBackground.alpha = Design.Alpha.gradientBackground
        gradientBackground.translatesAutoresizingMaskIntoConstraints = false

        // scroll + stack
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            gradientBackground.topAnchor.constraint(equalTo: view.topAnchor),
            gradientBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // --- Card 1: Title + Description
        let card1 = GlassCardView(appearance: currentCardAppearance())
        contentStack.addArrangedSubview(card1)
        let c1Stack = makeVStack(in: card1)
        c1Stack.addArrangedSubview(makeFieldRow(iconName: "exclamationmark.bubble.fill", titleView: titleField))
        c1Stack.addArrangedSubview(makeDivider())
        c1Stack.addArrangedSubview(descriptionView)

        // --- Card 2: Attachments
        let card2 = GlassCardView(appearance: currentCardAppearance())
        contentStack.addArrangedSubview(card2)
        let c2Stack = makeVStack(in: card2)
        c2Stack.addArrangedSubview(attachButton)
        attachmentsStack.axis = .horizontal
        attachmentsStack.spacing = 8
        c2Stack.addArrangedSubview(attachmentsStack)

        // --- Card 3: Diagnostics toggle
        let card3 = GlassCardView(appearance: currentCardAppearance())
        contentStack.addArrangedSubview(card3)
        let c3Stack = makeVStack(in: card3)
        let diagRow = makeSwitchRow(
            iconName: "wrench.and.screwdriver",
            title: "Include Diagnostics",
            switchControl: diagnosticsSwitch
        )
        diagnosticsSwitch.isOn = true
        c3Stack.addArrangedSubview(diagRow)

        // --- Send
        contentStack.addArrangedSubview(sendButton)
        contentStack.setCustomSpacing(24, after: sendButton)
    }
    
    private func setupKeyboardHandling() {
        let nc = NotificationCenter.default
        let willChange = nc.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            self?.handleKeyboard(note: note)
        }
        let willHide = nc.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            self?.handleKeyboard(note: note)
        }
        keyboardTokens = [willChange, willHide]
    }

    private func handleKeyboard(note: Notification) {
        guard
            let userInfo = note.userInfo,
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let willHide = note.name == UIResponder.keyboardWillHideNotification

        // Convert keyboard frame to our view's coordinate space
        let kbFrame = view.convert(endFrame, from: nil)
        let intersection = view.bounds.intersection(kbFrame)
        // Respect safe area; inset only the amount covering our content
        let bottomInset = max(0, intersection.height - view.safeAreaInsets.bottom)

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: UIView.AnimationOptions(rawValue: curveRaw << 16),
                       animations: {
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: willHide ? 0 : bottomInset, right: 0)
            self.scrollView.contentInset = insets
            self.scrollView.scrollIndicatorInsets = insets
            // Ensure the focused field stays visible
            if let focused = self.currentFirstResponder(), let fr = focused.superview {
                let rect = fr.convert(focused.frame, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -12), animated: false)
            }
        }, completion: nil)
    }

    private func currentFirstResponder() -> UIView? {
        func find(in view: UIView) -> UIView? {
            for sub in view.subviews {
                if sub.isFirstResponder { return sub }
                if let found = find(in: sub) { return found }
            }
            return nil
        }
        return find(in: view)
    }


    private func currentCardAppearance() -> GlassCardView.Appearance {
        let isDark = traitCollection.userInterfaceStyle == .dark
        return isDark ? .glass(dark: true, dimming: Design.Glass.cardDimming) : .solid
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        for v in contentStack.arrangedSubviews {
            (v as? GlassCardView)?.setAppearance(currentCardAppearance())
        }
    }

    // MARK: - Actions
    private func setupActions() {
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        titleField.addTarget(self, action: #selector(focusDescription), for: .editingDidEndOnExit)
    }

    @objc private func focusDescription() {
        descriptionView.becomeFirstResponder()
    }

    @objc private func attachTapped() {
        let sheet = UIAlertController(title: "Attach", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Take Snapshot Now", style: .default) { _ in
            if let img = self.snapshotWindow() {
                self.attachedImages.append(img)
            }
        })
        sheet.addAction(UIAlertAction(title: "Choose from Photos", style: .default) { _ in
            var cfg = PHPickerConfiguration(photoLibrary: .shared())
            cfg.selectionLimit = 3
            cfg.filter = .images
            let picker = PHPickerViewController(configuration: cfg)
            picker.delegate = self
            self.present(picker, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController { pop.sourceView = attachButton; pop.sourceRect = attachButton.bounds }
        present(sheet, animated: true)
    }

    @objc private func sendTapped() {
        let subjectTitle = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let shortTitle = subjectTitle, !shortTitle.isEmpty else {
            presentAlert(title: "Missing Title", message: "Please add a short summary.")
            return
        }

        let body = buildBody(includeDiagnostics: diagnosticsSwitch.isOn)

        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["jaskaranjvs@gmail.com"]) // TODO: set your address
            mail.setSubject("[Bug] \(shortTitle)")
            mail.setMessageBody(body, isHTML: false)
            for (idx, img) in attachedImages.enumerated() {
                if let data = img.jpegData(compressionQuality: 0.8) {
                    mail.addAttachmentData(data, mimeType: "image/jpeg", fileName: "screenshot_\(idx+1).jpg")
                }
            }
            present(mail, animated: true)
        } else {
            // Fallback to share sheet (text + images)
            var items: [Any] = [body]
            items.append(contentsOf: attachedImages)
            let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let pop = av.popoverPresentationController { pop.sourceView = sendButton; pop.sourceRect = sendButton.bounds }
            present(av, animated: true)
        }
    }
    @objc private func endEditingTap() { view.endEditing(true) }


    // MARK: - Helpers
    private func buildBody(includeDiagnostics: Bool) -> String {
        let desc = descriptionView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        var body = "Title:\n\(titleField.text ?? "")\n\nDescription:\n\(desc.isEmpty ? "(none)" : desc)"
        if includeDiagnostics {
            body += "\n\n--- Diagnostics ---\n" + Diagnostics.make()
        }
        return body
    }

    private func makeVStack(in card: GlassCardView) -> UIStackView {
        let st = UIStackView()
        st.axis = .vertical
        st.spacing = 12
        st.isLayoutMarginsRelativeArrangement = true
        st.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        card.contentView.addSubview(st)
        st.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            st.topAnchor.constraint(equalTo: card.contentView.topAnchor),
            st.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor),
            st.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor),
            st.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor),
        ])
        return st
    }

    private func makeFieldRow(iconName: String, titleView: UIView) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .secondaryLabel
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(icon)
        row.addArrangedSubview(titleView)
        return row
    }

    private func makeSwitchRow(iconName: String, title: String, switchControl: UISwitch) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .secondaryLabel

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17, weight: .regular)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        row.addArrangedSubview(icon)
        row.setCustomSpacing(12, after: icon)
        row.addArrangedSubview(label)
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(switchControl)
        return row
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: Design.Hairline.width).isActive = true
        return v
    }

    private func reloadAttachments() {
        attachmentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, img) in attachedImages.enumerated() {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 10
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.widthAnchor.constraint(equalToConstant: 64),
                iv.heightAnchor.constraint(equalTo: iv.widthAnchor)
            ])

            // remove button overlay
            let container = UIView()
            container.addSubview(iv)
            iv.frame = container.bounds
            iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let remove = UIButton(type: .system)
            remove.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            remove.addAction(UIAction { [weak self] _ in self?.attachedImages.remove(at: i) }, for: .touchUpInside)
            container.addSubview(remove)
            remove.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                remove.topAnchor.constraint(equalTo: container.topAnchor, constant: -6),
                remove.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 6)
            ])

            attachmentsStack.addArrangedSubview(container)
        }
    }

    private func snapshotWindow() -> UIImage? {
        guard let window = view.window ?? UIApplication.shared.windows.first else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
    }

    private func presentAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(.init(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - PHPicker
extension ReportBugViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }
        for item in results {
            if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
                item.itemProvider.loadObject(ofClass: UIImage.self) { value, _ in
                    if let img = value as? UIImage {
                        DispatchQueue.main.async { self.attachedImages.append(img) }
                    }
                }
            }
        }
    }
}

// MARK: - Small helpers

/// A UITextView with a placeholder label (keeps your aesthetic minimal)
final class PlaceholderTextView: UITextView, UITextViewDelegate {
    private let placeholderLabel = UILabel()
    private let placeholderInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

    init(placeholder: String) {
        super.init(frame: .zero, textContainer: nil)
        font = .systemFont(ofSize: 16)
        backgroundColor = .clear
        isScrollEnabled = false
        textContainerInset = placeholderInsets
        textContainer.lineFragmentPadding = 0

        placeholderLabel.text = placeholder
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.numberOfLines = 0
        addSubview(placeholderLabel)

        delegate = self
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Size placeholder to the usable text rect
        let insets = textContainerInset
        let width = bounds.width - insets.left - insets.right
        let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        placeholderLabel.frame = CGRect(x: insets.left,
                                        y: insets.top,
                                        width: width,
                                        height: size.height)
    }
    
    func textViewDidChange(_ textView: UITextView) { placeholderLabel.isHidden = !text.isEmpty }

    // Auto-grow
    override var intrinsicContentSize: CGSize {
        // Minimum height comfortable for 4 lines
        let base = super.intrinsicContentSize
        return CGSize(width: base.width, height: max(140, base.height))
    }
}


/// Gathers simple environment details.
enum Diagnostics {
    static func make() -> String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        let system = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        let model = deviceModel()
        let email = Auth.auth().currentUser?.email ?? "(unknown)"
        return """
        App: \(version) (\(build))
        OS: \(system) \(systemVersion)
        Device: \(model)
        User: \(email)
        Locale: \(Locale.current.identifier)
        """
    }

    private static func deviceModel() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(validatingUTF8: ptr) ?? "unknown"
            }
        }
        return machine
    }
}

