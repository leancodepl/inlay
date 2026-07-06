import UIKit

final class NativeAboutViewController: UIViewController {
    private let version: String
    private let onFeedback: (String) -> Void
    private var feedbackDelivered = false

    private let feedbackField = UITextField()

    init(version: String, onFeedback: @escaping (String) -> Void) {
        self.version = version
        self.onFeedback = onFeedback
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native About"
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Version: \(version)"
        label.font = .preferredFont(forTextStyle: .title2)

        feedbackField.borderStyle = .roundedRect
        feedbackField.placeholder = "Your feedback"
        feedbackField.accessibilityIdentifier = "aboutFeedbackField"

        var config = UIButton.Configuration.filled()
        config.title = "Send feedback & close"
        let sendButton = UIButton(configuration: config)
        sendButton.addAction(UIAction { [weak self] _ in self?.send() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, feedbackField, sendButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
        ])
    }

    private func send() {
        deliver(feedbackField.text ?? "")
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    /// Delivers [feedback] to the awaiting Flutter caller exactly once.
    private func deliver(_ feedback: String) {
        guard !feedbackDelivered else { return }
        feedbackDelivered = true
        onFeedback(feedback)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Closed without sending (back gesture / nav-bar back): the Flutter
        // caller still gets its result, empty.
        if isMovingFromParent || isBeingDismissed {
            deliver("")
        }
    }
}
