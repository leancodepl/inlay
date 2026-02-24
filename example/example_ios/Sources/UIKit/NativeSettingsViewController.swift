import UIKit

final class NativeSettingsViewController: UIViewController {
    private let userId: String
    private let scope: NativeStorageScope

    private lazy var store = UserPreferencesStore(storage: scope, userId: userId)

    private let displayNameValue = UILabel()
    private let emailValue = UILabel()
    private let darkModeValue = UILabel()
    private let themeValue = UILabel()

    init(userId: String) {
        self.userId = userId
        self.scope = KeyValueStorageImpl.shared.createScope()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native Settings"
        view.backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: [
            makeTitle("Display name"),
            displayNameValue,
            makeTitle("Email"),
            emailValue,
            makeTitle("Dark mode"),
            darkModeValue,
            makeTitle("Theme"),
            themeValue,
            makeButton("Set demo values", action: setDemoValues),
            makeButton("Toggle dark mode", action: toggleDarkMode),
            makeButton("Theme: system", action: { [weak self] in self?.setTheme(.system) }),
            makeButton("Theme: light", action: { [weak self] in self?.setTheme(.light) }),
            makeButton("Theme: dark", action: { [weak self] in self?.setTheme(.dark) }),
            makeButton("Open Flutter Profile", action: openFlutterProfile),
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])

        scope.startObserving { [weak self] _ in
            self?.render()
        }

        render()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            scope.dispose()
        }
    }

    private func setDemoValues() {
        store.displayName = "Native User"
        store.email = "native42@example.com"
        render()
    }

    private func toggleDarkMode() {
        store.darkMode.toggle()
        render()
    }

    private func setTheme(_ theme: AppTheme) {
        store.theme = theme
        render()
    }

    private func openFlutterProfile() {
        Add2AppNavigator.shared.push(
            from: self,
            route: ProfilePage(userId: userId, badges: nil)
        )
    }

    private func render() {
        displayNameValue.text = store.displayName
        emailValue.text = store.email
        darkModeValue.text = store.darkMode ? "on" : "off"
        themeValue.text = String(describing: store.theme)
    }

    private func makeTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    private func makeButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}
