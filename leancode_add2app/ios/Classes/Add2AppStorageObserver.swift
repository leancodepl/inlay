import Foundation
import Combine

/// SwiftUI-friendly bridge for observing and writing `KeyValueStorageImpl`.
///
/// Use with `@StateObject` to receive real-time storage updates and write
/// values from any SwiftUI view. Self-notification suppression is automatic —
/// writes through this observer never trigger the observer's own callback.
///
/// ```swift
/// struct MyView: View {
///     @StateObject private var storage = Add2AppStorageObserver()
///
///     var body: some View {
///         Text(name)
///             .onAppear {
///                 storage.startObserving { entries in
///                     for entry in entries {
///                         // update @State from entry.key / entry.value
///                     }
///                 }
///             }
///             .onDisappear {
///                 storage.stopObserving()
///             }
///     }
///
///     private func save() {
///         // Self-suppression is automatic — observer callback NOT called.
///         storage.put(key: "some_key", value: "new_value")
///     }
/// }
/// ```
///
/// ### Lifecycle
///
/// `@StateObject` keeps the instance alive for the view's lifetime.
/// The scope is automatically disposed in `deinit`, but calling
/// `stopObserving()` in `onDisappear` is recommended for deterministic
/// cleanup (especially when the view may reappear).
final class Add2AppStorageObserver: ObservableObject {

    /// The underlying storage scope. Use this to create generated store
    /// structs for type-safe access while retaining observer lifecycle.
    let scope: NativeStorageScope

    init() {
        scope = KeyValueStorageImpl.shared.createScope()
    }

    // MARK: - Observation

    /// Start observing storage changes.
    ///
    /// Every call to `startObserving` replaces the previous observer
    /// (calls `stopObserving()` first).
    ///
    /// - Parameter handler: Called on the **main queue** whenever storage
    ///   entries change (from Flutter engines or other native scopes).
    func startObserving(handler: @escaping ([StorageEntry]) -> Void) {
        scope.startObserving(handler)
    }

    /// Stop observing. Read/write methods still work.
    func stopObserving() {
        scope.stopObserving()
    }

    deinit {
        scope.dispose()
    }

    // MARK: - Write (auto-suppressed)

    /// Write a value. The observer callback is **not** triggered for this write.
    func put(key: String, value: String) {
        scope.put(key: key, value: value)
    }

    /// Write multiple values at once. The observer callback is **not** triggered.
    func putAll(entries: [StorageEntry]) {
        scope.putAll(entries: entries)
    }

    /// Remove a key. The observer callback is **not** triggered for this removal.
    @discardableResult
    func remove(key: String) -> Bool {
        return scope.remove(key: key)
    }

    /// Remove all keys with the given prefix. The observer callback is **not** triggered.
    func removeByPrefix(prefix: String) {
        scope.removeByPrefix(prefix: prefix)
    }

    /// Clear all storage. The observer callback is **not** triggered.
    func clear() {
        scope.clear()
    }

    // MARK: - Read

    /// Read a value by key.
    func get(key: String) -> String? {
        return scope.get(key: key)
    }

    /// Get all stored entries.
    func getAll() -> [StorageEntry] {
        return scope.getAll()
    }

    /// Get all entries whose keys start with the given prefix.
    func getByPrefix(prefix: String) -> [StorageEntry] {
        return scope.getByPrefix(prefix: prefix)
    }
}
