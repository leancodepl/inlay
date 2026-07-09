import UIKit
import inlay

final class NativeSettingsViewController: UIViewController {
    private let userId: String
    private let scope: NativeStorageScope

    private lazy var store = UserPreferencesStore(storage: scope, userId: userId)

    private let displayNameValue = UILabel()
    private let emailValue = UILabel()
    private let darkModeValue = UILabel()
    private let themeValue = UILabel()
    private let tagsValue = UILabel()
    private let notifPrefsValue = UILabel()
    private let routingValue = UILabel()

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
            makeTitle("Tags"),
            tagsValue,
            makeTitle("Notification preferences"),
            notifPrefsValue,
            makeButton("Set demo values", action: setDemoValues),
            makeButton("Add 'ios' tag", action: addTag),
            makeButton("Set notification prefs", action: setNotifPrefs),
            makeButton("Clear notification prefs", action: clearNotifPrefs),
            makeButton("Toggle dark mode", action: toggleDarkMode),
            makeButton("Theme: system", action: { [weak self] in self?.setTheme(.system) }),
            makeButton("Theme: light", action: { [weak self] in self?.setTheme(.light) }),
            makeButton("Theme: dark", action: { [weak self] in self?.setTheme(.dark) }),
            // App-level appearance (InlayAppearance): applied by every
            // Flutter engine's MaterialApp, unlike the store-based theme
            // demo above which is plain shared state.
            makeButton("Flutter theme: system", action: { InlayAppearance.shared.themeMode = .system }),
            makeButton("Flutter theme: dark", action: { InlayAppearance.shared.themeMode = .dark }),
            makeButton("Flutter language: polski", action: { InlayAppearance.shared.localeLanguageTag = "pl" }),
            makeButton("Flutter language: system", action: { InlayAppearance.shared.localeLanguageTag = nil }),
            makeButton("Open Flutter Profile", action: openFlutterProfile),
            // Framework-level controls: engine prewarming + the Dart
            // entrypoint used for new engines (routing integration demo).
            makeTitle("Framework"),
            makePrewarmSwitchRow(),
            makeTitle("Routing entrypoint"),
            routingValue,
            makeButton("Routing: go_router", action: { [weak self] in self?.setRouting("inlayGoRouterMain") }),
            makeButton("Routing: auto_route", action: { [weak self] in self?.setRouting("inlayAutoRouteMain") }),
            makeButton("Routing: imperative", action: { [weak self] in self?.setRouting("inlayImperativeMain") }),
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
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

    private func addTag() {
        var s = store
        if !s.tags.contains("ios") {
            s.tags = s.tags + ["ios"]
        }
        render()
    }

    private func setNotifPrefs() {
        var s = store
        s.notificationPreferences = NotificationPreferences(sound: "Bell", vibration: true)
        render()
    }

    private func clearNotifPrefs() {
        var s = store
        s.notificationPreferences = nil
        render()
    }

    private func setRouting(_ entrypoint: String) {
        InlayNavigator.shared.setDartEntrypoint(entrypoint)
        render()
    }

    private func openFlutterProfile() {
        InlayNavigator.shared.push(
            from: self,
            route: ProfilePage(userId: userId, badges: nil)
        )
    }

    private func render() {
        displayNameValue.text = store.displayName
        emailValue.text = store.email
        darkModeValue.text = store.darkMode ? "on" : "off"
        themeValue.text = String(describing: store.theme)
        let tags = store.tags
        tagsValue.text = tags.isEmpty ? "(none)" : tags.joined(separator: ", ")
        if let prefs = store.notificationPreferences {
            notifPrefsValue.text = "sound=\(prefs.sound), vibration=\(prefs.vibration)"
        } else {
            notifPrefsValue.text = "(not set)"
        }
        routingValue.text = InlayNavigator.shared.dartEntrypoint
    }

    private func makePrewarmSwitchRow() -> UIView {
        let label = UILabel()
        label.text = "Engine prewarming"
        let toggle = UISwitch()
        toggle.isOn = InlayNavigator.shared.isPrewarmEnabled
        toggle.addAction(
            UIAction { action in
                guard let toggle = action.sender as? UISwitch else { return }
                InlayNavigator.shared.setPrewarmEnabled(toggle.isOn)
            },
            for: .valueChanged
        )
        let row = UIStackView(arrangedSubviews: [label, toggle])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        return row
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
