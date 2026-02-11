import UIKit

/// ADD2APP: Native iOS duplicate of the Sounds & Notifications screen.
///
/// Reads/writes the same `KeyValueStorageImpl` that the Flutter screen uses
/// via Pigeon. The framework handles:
/// - **Self-notification suppression**: writes via `putFromNative` with our
///   `observerId` do not trigger our own observer callback.
/// - **Main-thread delivery**: observer callbacks always arrive on the main queue.
///
/// Also provides a button to launch the Flutter equivalent via `Add2AppNavigator`.
///
/// Equivalent of Android's `NativeSoundsNotificationsActivity`.
final class NativeSoundsNotificationsViewController: UIViewController, NativeStorageObserver {

    // MARK: - Properties

    private let recipientId: String
    private var observerId: Int = 0

    // UI references
    private let muteSwitch = UISwitch()
    private let previewsSwitch = UISwitch()
    private let soundValueLabel = UILabel()
    private let vibrationValueLabel = UILabel()

    // Suppress observer callbacks during programmatic UI updates
    private var updatingUI = false

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
        loadState()
        observerId = KeyValueStorageImpl.shared.addNativeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadState()
    }

    deinit {
        KeyValueStorageImpl.shared.removeNativeObserver(observerId)
    }

    // MARK: - Storage key helpers

    private func key(_ field: String) -> String {
        "sounds_notifications/\(recipientId)/\(field)"
    }

    // MARK: - Load from storage

    private func loadState() {
        updatingUI = true
        muteSwitch.isOn = KeyValueStorageImpl.shared.getFromNative(key: key("mute")) == "true"
        previewsSwitch.isOn = KeyValueStorageImpl.shared.getFromNative(key: key("previews")) != "false"
        soundValueLabel.text = KeyValueStorageImpl.shared.getFromNative(key: key("sound")) ?? "Default"
        vibrationValueLabel.text = KeyValueStorageImpl.shared.getFromNative(key: key("vibration")) ?? "Default"
        updatingUI = false
    }

    // MARK: - NativeStorageObserver (only fires for changes from OTHER sources)

    func onStorageChanged(entries: [StorageEntry]) {
        let prefix = "sounds_notifications/\(recipientId)/"
        updatingUI = true
        for entry in entries {
            guard entry.key.hasPrefix(prefix) else { continue }
            let field = String(entry.key.dropFirst(prefix.count))
            switch field {
            case "mute":
                muteSwitch.isOn = entry.value == "true"
            case "previews":
                previewsSwitch.isOn = entry.value != "false"
            case "sound":
                soundValueLabel.text = entry.value.isEmpty ? "Default" : entry.value
            case "vibration":
                vibrationValueLabel.text = entry.value.isEmpty ? "Default" : entry.value
            default:
                break
            }
        }
        updatingUI = false
    }

    // MARK: - Actions

    @objc private func muteChanged(_ sender: UISwitch) {
        guard !updatingUI else { return }
        KeyValueStorageImpl.shared.putFromNative(key: key("mute"), value: String(sender.isOn), excludeObserver: observerId)
    }

    @objc private func previewsChanged(_ sender: UISwitch) {
        guard !updatingUI else { return }
        KeyValueStorageImpl.shared.putFromNative(key: key("previews"), value: String(sender.isOn), excludeObserver: observerId)
    }

    @objc private func showSoundPicker() {
        let sounds = ["Default", "Signal", "Pulse", "Chime", "Bamboo", "None"]
        let alert = UIAlertController(title: "Notification Sound", message: nil, preferredStyle: .actionSheet)
        for sound in sounds {
            alert.addAction(UIAlertAction(title: sound, style: .default) { [weak self] _ in
                guard let self else { return }
                KeyValueStorageImpl.shared.putFromNative(key: self.key("sound"), value: sound, excludeObserver: self.observerId)
                self.soundValueLabel.text = sound
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showVibrationPicker() {
        let patterns = ["Default", "Short", "Long", "Double", "None"]
        let alert = UIAlertController(title: "Vibration Pattern", message: nil, preferredStyle: .actionSheet)
        for pattern in patterns {
            alert.addAction(UIAlertAction(title: pattern, style: .default) { [weak self] _ in
                guard let self else { return }
                KeyValueStorageImpl.shared.putFromNative(key: self.key("vibration"), value: pattern, excludeObserver: self.observerId)
                self.vibrationValueLabel.text = pattern
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func openFlutterScreen() {
        Add2AppNavigator.shared.push(
            from: self,
            page: PageSettings(
                routeId: "soundsNotifications",
                params: ["contactId": recipientId]
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

        vibrationValueLabel.text = "Default"
        vibrationValueLabel.font = .systemFont(ofSize: 14)
        vibrationValueLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(vibrationValueLabel)

        let changeVibBtn = makeButton(title: "Change vibration", action: #selector(showVibrationPicker))
        stack.addArrangedSubview(changeVibBtn)

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
