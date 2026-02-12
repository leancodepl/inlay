import Foundation
import Combine

/// SwiftUI-friendly bridge for observing `KeyValueStorageImpl` changes.
///
/// Use with `@StateObject` to receive real-time storage updates in any
/// SwiftUI view:
///
/// ```swift
/// struct MyView: View {
///     @StateObject private var storageObserver = Add2AppStorageObserver()
///
///     var body: some View {
///         Text(name)
///             .onAppear {
///                 storageObserver.startObserving { entries in
///                     for entry in entries {
///                         // update @State from entry.key / entry.value
///                     }
///                 }
///             }
///             .onDisappear {
///                 storageObserver.stopObserving()
///             }
///     }
/// }
/// ```
///
/// ### Self-notification suppression
///
/// Pass `storageObserver.observerId` to
/// `KeyValueStorageImpl.shared.putFromNative(key:value:excludeObserver:)`
/// so writes originating from this view don't trigger the observer callback:
///
/// ```swift
/// KeyValueStorageImpl.shared.putFromNative(
///     key: "some_key",
///     value: "new_value",
///     excludeObserver: storageObserver.observerId
/// )
/// ```
///
/// ### Lifecycle
///
/// `@StateObject` keeps the instance alive for the view's lifetime.
/// The observer is automatically unregistered in `deinit`, but calling
/// `stopObserving()` in `onDisappear` is recommended for deterministic
/// cleanup (especially when the view may reappear).
///
/// Equivalent of Android's closure-based `KeyValueStorageImpl.addAndroidObserver`.
final class Add2AppStorageObserver: ObservableObject, NativeStorageObserver {

    /// The observer ID returned by `KeyValueStorageImpl.addNativeObserver`.
    /// Use this with `putFromNative(excludeObserver:)` to suppress
    /// self-notifications.
    private(set) var observerId: Int = 0

    private var handler: (([StorageEntry]) -> Void)?

    // MARK: - Registration

    /// Start observing storage changes.
    ///
    /// Every call to `startObserving` replaces the previous registration
    /// (calls `stopObserving()` first).
    ///
    /// - Parameter handler: Called on the **main queue** whenever storage
    ///   entries change (from Flutter engines or other native observers).
    func startObserving(handler: @escaping ([StorageEntry]) -> Void) {
        stopObserving()
        self.handler = handler
        observerId = KeyValueStorageImpl.shared.addNativeObserver(self)
    }

    /// Stop observing and release the handler closure.
    func stopObserving() {
        guard observerId != 0 else { return }
        KeyValueStorageImpl.shared.removeNativeObserver(observerId)
        observerId = 0
        handler = nil
    }

    deinit {
        stopObserving()
    }

    // MARK: - NativeStorageObserver

    func onStorageChanged(entries: [StorageEntry]) {
        handler?(entries)
    }
}
