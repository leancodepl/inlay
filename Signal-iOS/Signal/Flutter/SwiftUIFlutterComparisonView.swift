import SwiftUI
import UIKit
import leancode_add2app

// MARK: - Hosting controller (UIKit → SwiftUI bridge)

/// `UIViewController` that hosts the SwiftUI `ComparisonNavigationView`.
///
/// Push this from any `UINavigationController` the same way you push any VC:
/// ```swift
/// let vc = SwiftUIFlutterComparisonViewController(recipientId: thread.uniqueId)
/// navigationController?.pushViewController(vc, animated: true)
/// ```
///
/// Equivalent of Android's `ComposeFlutterComparisonActivity`.
@available(iOS 16.0, *)
final class SwiftUIFlutterComparisonViewController: UIHostingController<ComparisonNavigationView> {

    init(recipientId: String) {
        super.init(rootView: ComparisonNavigationView(recipientId: recipientId))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the UIKit navigation bar — SwiftUI provides its own.
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore the UIKit navigation bar for the previous VC.
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - Navigation graph

/// Root SwiftUI view with a `NavigationStack` containing three destinations:
///
/// 1. **Hub** — lets the user choose native SwiftUI or Flutter.
/// 2. **Native SwiftUI** — Sounds & Notifications built with SwiftUI,
///    reading/writing `KeyValueStorageImpl`.
/// 3. **Flutter** — the same screen rendered by the Flutter engine via
///    `Add2AppFlutterView`, also reading/writing `KeyValueStorageImpl`.
@available(iOS 16.0, *)
struct ComparisonNavigationView: View {

    let recipientId: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ComparisonHubView(
                recipientId: recipientId,
                onBack: { dismiss() }
            )
        }
    }
}

// MARK: - Hub screen

@available(iOS 16.0, *)
private struct ComparisonHubView: View {

    let recipientId: String
    let onBack: () -> Void

    var body: some View {
        List {
            Section {
                Text("Contact: \(recipientId)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Both screens read/write the same Pigeon KeyValueStorage. Changes made in one sync to the other in real-time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Choose implementation") {

                // ── Native SwiftUI ──
                NavigationLink {
                    NativeSwiftUISoundsNotifications(recipientId: recipientId)
                } label: {
                    HStack(spacing: 16) {
                        Text("📱")
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Native SwiftUI")
                                .font(.headline)
                            Text("SwiftUI screen inside this NavigationStack")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // ── Flutter ──
                NavigationLink {
                    Add2AppFlutterView(
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
                            ],
                            fallbackChannel: .sms
                        )
                    )
                    .ignoresSafeArea()
                    .navigationTitle("Sounds & Notifications")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack(spacing: 16) {
                        Text("🦋")
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Flutter (Add2AppFlutterView)")
                                .font(.headline)
                            Text("Flutter screen via Add2AppFlutterView in same NavigationStack")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                Text("Both screens are destinations in the same SwiftUI NavigationStack. The Flutter screen is embedded seamlessly using Add2AppFlutterView from leancode_add2app. Back navigation and pop() work correctly via SwiftUI's dismiss action.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sounds & Notifications")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}

// MARK: - Native SwiftUI Sounds & Notifications screen

@available(iOS 16.0, *)
private struct NativeSwiftUISoundsNotifications: View {

    let recipientId: String

    // ── State (initialised from real storage values) ──
    @State private var muteNotifications: Bool
    @State private var showPreviews: Bool
    @State private var notificationSound: String
    @State private var vibrationLevel: VibrationLevel
    @State private var behavior: NotificationBehavior

    @State private var showSoundPicker = false
    @State private var showVibrationPicker = false
    @State private var showBehaviorPicker = false

    /// Framework-provided observer with built-in read/write/observe.
    /// Self-notification suppression is automatic.
    @StateObject private var storage = Add2AppStorageObserver()

    private var store: SoundsNotificationsStore {
        SoundsNotificationsStore(storage: storage.scope, contactId: recipientId)
    }

    init(recipientId: String) {
        self.recipientId = recipientId

        let scope = KeyValueStorageImpl.shared.createScope()
        let store = SoundsNotificationsStore(storage: scope, contactId: recipientId)
        _muteNotifications = State(initialValue: store.mute)
        _showPreviews = State(initialValue: store.showPreviews)
        _notificationSound = State(initialValue: store.sound)
        _vibrationLevel = State(initialValue: store.vibration)
        _behavior = State(initialValue: store.behavior)
        scope.dispose()
    }

    private func reloadFromStorage() {
        muteNotifications = store.mute
        showPreviews = store.showPreviews
        notificationSound = store.sound
        vibrationLevel = store.vibration
        behavior = store.behavior
    }

    // MARK: - Custom bindings (write to storage only on user interaction)

    private var muteBinding: Binding<Bool> {
        Binding(
            get: { muteNotifications },
            set: { newValue in
                muteNotifications = newValue
                var s = store; s.mute = newValue
            }
        )
    }

    private var previewsBinding: Binding<Bool> {
        Binding(
            get: { showPreviews },
            set: { newValue in
                showPreviews = newValue
                var s = store; s.showPreviews = newValue
            }
        )
    }

    var body: some View {
        List {
            // ── Banner ──
            Section {
                Text("Native SwiftUI")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .listRowBackground(Color.blue.opacity(0.1))
            }

            // ── Contact info ──
            Section {
                Text("Contact: \(recipientId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // ── Mute ──
            Section {
                Toggle(isOn: muteBinding) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Mute notifications")
                            if muteNotifications {
                                Text("Notifications are muted")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Text(muteNotifications ? "🔕" : "🔔")
                    }
                }
            }

            // ── Notification sound ──
            Section {
                Button {
                    showSoundPicker = true
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Notification sound")
                                    .foregroundStyle(.primary)
                                Text(notificationSound)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Text("🎵")
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }

            // ── Vibration ──
            Section {
                Button {
                    showVibrationPicker = true
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Vibrate")
                                    .foregroundStyle(.primary)
                                Text(vibrationLevel.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Text("📳")
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }

            // ── Behavior ──
            Section {
                Button {
                    showBehaviorPicker = true
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Notification behavior")
                                    .foregroundStyle(.primary)
                                Text(behavior.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Text("🎚")
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }

            // ── Message notifications ──
            Section("Message Notifications") {
                Toggle(isOn: previewsBinding) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Show previews")
                            Text("Display message content in notifications")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Text("👁")
                    }
                }
            }

            // ── Info ──
            Section {
                Text("These settings override the default notification settings for this conversation.\n\nState is synced across all Flutter engines & native iOS via Pigeon KeyValueStorage. Changes you make here will appear instantly on the Flutter version and vice versa.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sounds & Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            storage.startObserving { entries in
                guard store.containsChanges(in: entries) else { return }
                reloadFromStorage()
            }

            reloadFromStorage()
        }
        .onDisappear {
            storage.stopObserving()
        }
        .confirmationDialog("Notification Sound", isPresented: $showSoundPicker) {
            ForEach(["Default", "Signal", "Pulse", "Chime", "Bamboo", "None"], id: \.self) { sound in
                Button(sound) {
                    notificationSound = sound
                    var s = store; s.sound = sound
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Vibration Pattern", isPresented: $showVibrationPicker) {
            ForEach(VibrationLevel.allCases, id: \.rawValue) { level in
                Button(level.label) {
                    vibrationLevel = level
                    var s = store; s.vibration = level
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Notification Behavior", isPresented: $showBehaviorPicker) {
            ForEach(NotificationBehavior.allCases, id: \.rawValue) { item in
                Button(item.label) {
                    behavior = item
                    var s = store; s.behavior = item
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

