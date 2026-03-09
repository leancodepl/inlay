import UIKit
import leancode_add2app

/// ADD2APP: Native iOS duplicate of the Sounds & Notifications screen.
///
/// Reads/writes the same `KeyValueStorageImpl` that the Flutter screen uses
/// via Pigeon. Uses `NativeStorageScope` which handles:
/// - **Self-notification suppression**: writes through the scope do not trigger
///   the scope's own observer callback, so there is no need for `updatingUI`
///   guard flags or manual `observerId` tracking.
/// - **Main-thread delivery**: observer callbacks always arrive on the main queue.
///
/// Also provides a button to launch the Flutter equivalent via `Add2AppNavigator`.
///
/// Equivalent of Android's `NativeSoundsNotificationsActivity`.
final class NativeSoundsNotificationsViewController: UIViewController {

    // MARK: - Properties

    private let recipientId: String

    /// Scoped storage handle — read, write, and observe with auto-suppression.
    private var storage: NativeStorageScope!
    private var store: SoundsNotificationsStore!

    // UI references
    private let muteSwitch = UISwitch()
    private let previewsSwitch = UISwitch()
    private let soundValueLabel = UILabel()
    private let vibrationValueLabel = UILabel()
    private let behaviorValueLabel = UILabel()

    // MARK: - Init

    init(recipientId: String) {
        self.recipientId = recipientId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Factory

    static func create(recipientId: String?) -> NativeSoundsNotificationsViewController {
        return NativeSoundsNotificationsViewController(recipientId: recipientId ?? "1")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sounds & Notifications"
        view.backgroundColor = .systemBackground
        buildUI()

        storage = KeyValueStorageImpl.shared.createScope()
        store = SoundsNotificationsStore(storage: storage, contactId: recipientId)
        loadState()

        storage.startObserving { [weak self] entries in
            self?.onStorageChanged(entries: entries)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadState()
    }

    deinit {
        storage?.dispose()
    }

    // MARK: - Load from storage

    private func loadState() {
        muteSwitch.isOn = store.mute
        previewsSwitch.isOn = store.showPreviews
        soundValueLabel.text = store.sound
        vibrationValueLabel.text = store.vibration.label
        behaviorValueLabel.text = store.behavior.label
    }

    // MARK: - Observer callback (only fires for changes from OTHER sources)

    private func onStorageChanged(entries: [StorageEntry]) {
        if store.containsChanges(in: entries) {
            loadState()
        }
    }

    // MARK: - Actions

    @objc private func muteChanged(_ sender: UISwitch) {
        store.mute = sender.isOn
    }

    @objc private func previewsChanged(_ sender: UISwitch) {
        store.showPreviews = sender.isOn
    }

    @objc private func showSoundPicker() {
        let sounds = ["Default", "Signal", "Pulse", "Chime", "Bamboo", "None"]
        let alert = UIAlertController(title: "Notification Sound", message: nil, preferredStyle: .actionSheet)
        for sound in sounds {
            alert.addAction(UIAlertAction(title: sound, style: .default) { [weak self] _ in
                guard let self else { return }
                self.store.sound = sound
                self.soundValueLabel.text = sound
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showVibrationPicker() {
        let alert = UIAlertController(title: "Vibration Pattern", message: nil, preferredStyle: .actionSheet)
        for level in VibrationLevel.allCases {
            alert.addAction(UIAlertAction(title: level.label, style: .default) { [weak self] _ in
                guard let self else { return }
                self.store.vibration = level
                self.vibrationValueLabel.text = level.label
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showBehaviorPicker() {
        let alert = UIAlertController(title: "Notification Behavior", message: nil, preferredStyle: .actionSheet)
        for behavior in NotificationBehavior.allCases {
            alert.addAction(UIAlertAction(title: behavior.label, style: .default) { [weak self] _ in
                guard let self else { return }
                self.store.behavior = behavior
                self.behaviorValueLabel.text = behavior.label
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func openFlutterScreen() {
        Add2AppNavigator.shared.push(
            from: self,
            route: SoundsNotificationsPage(
                contactId: recipientId,
                preferences: NotificationPreferences(
                    sound: .chime,
                    channels: [.push, .email],
                    quietHours: QuietHours(fromHour: 22, toHour: 7)
                ),
                presets: [
                    NotificationPreset(
                        name: "Work",
                        preferences: NotificationPreferences(
                            sound: .pop,
                            channels: [.push],
                            quietHours: nil
                        )
                    ),
                    NotificationPreset(
                        name: "Silent",
                        preferences: NotificationPreferences(
                            sound: .defaultSound,
                            channels: [.sms],
                            quietHours: QuietHours(fromHour: 0, toHour: 24)
                        )
                    ),
                ],
                fallbackChannel: .sms
            )
        )
    }

    // MARK: - Build UI

    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        // ── Title ──
        let titleLabel = UILabel()
        titleLabel.text = "Sounds & Notifications (Native iOS)"
        titleLabel.font = .boldSystemFont(ofSize: 22)
        stack.addArrangedSubview(titleLabel)

        let contactLabel = UILabel()
        contactLabel.text = "Contact: \(recipientId)"
        contactLabel.font = .systemFont(ofSize: 14)
        contactLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(contactLabel)

        stack.addArrangedSubview(makeDivider())

        // ── Mute switch ──
        let muteRow = makeSwitchRow(title: "Mute notifications", control: muteSwitch)
        muteSwitch.addTarget(self, action: #selector(muteChanged), for: .valueChanged)
        stack.addArrangedSubview(muteRow)

        stack.addArrangedSubview(makeDivider())

        // ── Notification sound ──
        let soundTitle = UILabel()
        soundTitle.text = "Notification sound"
        soundTitle.font = .systemFont(ofSize: 16)
        stack.addArrangedSubview(soundTitle)

        soundValueLabel.text = "Default"
        soundValueLabel.font = .systemFont(ofSize: 14)
        soundValueLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(soundValueLabel)

        let changeSoundBtn = makeButton(title: "Change sound", action: #selector(showSoundPicker))
        stack.addArrangedSubview(changeSoundBtn)

        stack.addArrangedSubview(makeDivider())

        // ── Vibration ──
        let vibTitle = UILabel()
        vibTitle.text = "Vibration pattern"
        vibTitle.font = .systemFont(ofSize: 16)
        stack.addArrangedSubview(vibTitle)

        vibrationValueLabel.text = VibrationLevel.normal.label
        vibrationValueLabel.font = .systemFont(ofSize: 14)
        vibrationValueLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(vibrationValueLabel)

        let changeVibBtn = makeButton(title: "Change vibration", action: #selector(showVibrationPicker))
        stack.addArrangedSubview(changeVibBtn)

        stack.addArrangedSubview(makeDivider())

        // ── Behavior ──
        let behaviorTitle = UILabel()
        behaviorTitle.text = "Notification behavior"
        behaviorTitle.font = .systemFont(ofSize: 16)
        stack.addArrangedSubview(behaviorTitle)

        behaviorValueLabel.text = NotificationBehavior.defaultBehavior.label
        behaviorValueLabel.font = .systemFont(ofSize: 14)
        behaviorValueLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(behaviorValueLabel)

        let changeBehaviorBtn = makeButton(
            title: "Change behavior",
            action: #selector(showBehaviorPicker)
        )
        stack.addArrangedSubview(changeBehaviorBtn)

        stack.addArrangedSubview(makeDivider())

        // ── Show previews ──
        let previewsRow = makeSwitchRow(title: "Show previews", control: previewsSwitch)
        previewsSwitch.addTarget(self, action: #selector(previewsChanged), for: .valueChanged)
        stack.addArrangedSubview(previewsRow)

        stack.addArrangedSubview(makeDivider())

        // ── Info ──
        let infoLabel = UILabel()
        infoLabel.text = """
            This native screen reads/writes the same Pigeon KeyValueStorage \
            that the Flutter Sounds & Notifications screen uses. \
            Changes sync in real-time across all Flutter engine isolates and this ViewController.
            """
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        stack.addArrangedSubview(infoLabel)

        stack.addArrangedSubview(makeDivider())

        // ── Open Flutter button ──
        let flutterBtn = makeButton(title: "Open Flutter Sounds & Notifications", action: #selector(openFlutterScreen))
        stack.addArrangedSubview(flutterBtn)
    }

    // MARK: - UI helpers

    private func makeDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        return view
    }

    private func makeSwitchRow(title: String, control: UISwitch) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)

        let row = UIStackView(arrangedSubviews: [label, control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        row.isLayoutMarginsRelativeArrangement = true
        return row
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.contentHorizontalAlignment = .leading
        return btn
    }
}

extension VibrationLevel: @retroactive CaseIterable {
    public static var allCases: [VibrationLevel] { [.off, .normal, .intense] }

    var label: String {
        switch self {
        case .off: return "Off"
        case .normal: return "Normal"
        case .intense: return "Intense"
        }
    }
}

extension NotificationBehavior: @retroactive CaseIterable {
    public static var allCases: [NotificationBehavior] { [.defaultBehavior, .mentionsOnly, .muted] }

    var label: String {
        switch self {
        case .defaultBehavior: return "Default"
        case .mentionsOnly: return "Mentions only"
        case .muted: return "Muted"
        }
    }
}
