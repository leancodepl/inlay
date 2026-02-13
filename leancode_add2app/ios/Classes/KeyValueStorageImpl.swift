import Foundation
import Flutter

// MARK: - NativeStorageScope

/// Scoped handle for native iOS code to read, write, and optionally observe
/// `KeyValueStorageImpl`.
///
/// All write operations (`put`, `putAll`, `remove`, `removeByPrefix`, `clear`)
/// automatically suppress the observer callback so you never receive
/// notifications about your own changes.
///
/// Observation is opt-in:
/// - ``startObserving(_:)`` — register a callback for external changes.
/// - ``stopObserving()`` — unregister the callback (read/write still works).
/// - ``dispose()`` — stop observing and release the scope.
///
/// Create via `KeyValueStorageImpl.shared.createScope()`.
///
/// ### Example
///
/// ```swift
/// let storage = KeyValueStorageImpl.shared.createScope()
///
/// // Read / write (works immediately, no observer needed)
/// storage.put(key: "foo", value: "bar")
/// let v = storage.get(key: "foo")
///
/// // Optionally start observing
/// storage.startObserving { entries in
///     for entry in entries { /* react to external changes */ }
/// }
///
/// storage.put(key: "foo", value: "baz")  // observer NOT called
///
/// storage.stopObserving()                // stop receiving callbacks
/// storage.dispose()                      // clean up
/// ```
final class NativeStorageScope {

    private var onChange: (([StorageEntry]) -> Void)?

    internal init() {}

    // MARK: - Observation

    /// Start observing storage changes from other sources (Flutter engines
    /// or other native scopes). Replaces any previous observer.
    ///
    /// The `onChange` callback is invoked on the **main queue**.
    func startObserving(_ onChange: @escaping ([StorageEntry]) -> Void) {
        stopObserving()
        self.onChange = onChange
        KeyValueStorageImpl.shared.registerScope(self)
    }

    /// Stop observing. The scope remains usable for read/write; only the
    /// observer callback is removed.
    func stopObserving() {
        if onChange != nil {
            KeyValueStorageImpl.shared.unregisterScope(self)
            onChange = nil
        }
    }

    // MARK: - Write (auto-suppressed)

    func put(key: String, value: String) {
        KeyValueStorageImpl.shared.putInternal(
            entry: StorageEntry(key: key, value: value),
            excludeScope: self
        )
    }

    func putAll(entries: [StorageEntry]) {
        KeyValueStorageImpl.shared.putAllInternal(entries: entries, excludeScope: self)
    }

    @discardableResult
    func remove(key: String) -> Bool {
        return KeyValueStorageImpl.shared.removeInternal(key: key, excludeScope: self)
    }

    func removeByPrefix(prefix: String) {
        KeyValueStorageImpl.shared.removeByPrefixInternal(prefix: prefix, excludeScope: self)
    }

    func clear() {
        KeyValueStorageImpl.shared.clearInternal(excludeScope: self)
    }

    // MARK: - Read

    func get(key: String) -> String? {
        return KeyValueStorageImpl.shared.getInternal(key: key)?.value
    }

    func getAll() -> [StorageEntry] {
        return KeyValueStorageImpl.shared.getAllInternal()
    }

    func getByPrefix(prefix: String) -> [StorageEntry] {
        return KeyValueStorageImpl.shared.getByPrefixInternal(prefix: prefix)
    }

    // MARK: - Internal: observer delivery

    internal func deliverChange(entries: [StorageEntry]) {
        onChange?(entries)
    }

    // MARK: - Lifecycle

    /// Stop observing (if active) and release the scope.
    /// After this call the scope should not be used.
    func dispose() {
        stopObserving()
    }
}

// MARK: - KeyValueStorageImpl

/// Framework-level key-value storage backed by an in-memory dictionary.
///
/// Single source of truth that bridges iOS native code and any number of
/// Flutter engine isolates (engine group).
///
/// ### Usage for native iOS code
///
/// Create a ``NativeStorageScope`` via ``createScope()`` to read, write,
/// and optionally observe storage changes. Observation is opt-in via
/// ``NativeStorageScope/startObserving(_:)`` /
/// ``NativeStorageScope/stopObserving()``:
///
/// ```swift
/// let storage = KeyValueStorageImpl.shared.createScope()
///
/// storage.put(key: "key", value: "value")
/// let v = storage.get(key: "key")
///
/// storage.startObserving { entries in /* react */ }
/// storage.dispose()
/// ```
///
/// Design decisions (mirrors Android `KeyValueStorageImpl`):
/// - **Self-notification suppression**: when a write originates from a specific
///   source (a Flutter engine or a native scope), that source is *not*
///   notified back about its own change.
/// - **Main-thread dispatch**: all observer callbacks (Flutter and native) are
///   dispatched on the main queue so consumers never need `DispatchQueue.main`.
/// - **Thread-safe store**: reads/writes are serialised on a private queue;
///   observer registries are protected by `NSLock`.
final class KeyValueStorageImpl: NSObject {

    // MARK: - Singleton

    static let shared = KeyValueStorageImpl()

    private override init() {
        super.init()
    }

    // MARK: - Data store (serial queue for thread safety)

    private let storeQueue = DispatchQueue(label: "co.leancode.add2app.KeyValueStorage", attributes: .concurrent)
    private var store: [String: String] = [:]

    // MARK: - Flutter engine registry

    private var flutterApis: [ObjectIdentifier: KeyValueStorageFlutterApi] = [:]
    private let flutterApisLock = NSLock()

    // MARK: - Native scope (observer) registry

    private var nativeScopes: [NativeStorageScope] = []
    private let nativeScopesLock = NSLock()

    // MARK: - Engine lifecycle

    func attachToEngine(_ engine: FlutterEngine) {
        let engineId = ObjectIdentifier(engine)
        let messenger = engine.binaryMessenger

        let proxy = EngineProxy(impl: self, engineId: engineId)
        KeyValueStorageHostApiSetup.setUp(binaryMessenger: messenger, api: proxy)

        let flutterApi = KeyValueStorageFlutterApi(binaryMessenger: messenger)
        flutterApisLock.lock()
        flutterApis[engineId] = flutterApi
        flutterApisLock.unlock()
    }

    func detachFromEngine(_ engine: FlutterEngine) {
        let engineId = ObjectIdentifier(engine)
        let messenger = engine.binaryMessenger
        KeyValueStorageHostApiSetup.setUp(binaryMessenger: messenger, api: nil)

        flutterApisLock.lock()
        flutterApis.removeValue(forKey: engineId)
        flutterApisLock.unlock()
    }

    // MARK: - Public API: scoped access for native iOS code

    /// Create a ``NativeStorageScope`` for reading and writing storage.
    ///
    /// The scope can optionally observe changes via
    /// ``NativeStorageScope/startObserving(_:)``. Writes through the scope
    /// automatically suppress the observer callback (self-notification
    /// suppression).
    ///
    /// Call ``NativeStorageScope/dispose()`` when you no longer need the
    /// scope (e.g. in `deinit`, `onDisappear`).
    func createScope() -> NativeStorageScope {
        return NativeStorageScope()
    }

    // MARK: - Internal: scope observer registration

    internal func registerScope(_ scope: NativeStorageScope) {
        nativeScopesLock.lock()
        nativeScopes.append(scope)
        nativeScopesLock.unlock()
    }

    internal func unregisterScope(_ scope: NativeStorageScope) {
        nativeScopesLock.lock()
        nativeScopes.removeAll { $0 === scope }
        nativeScopesLock.unlock()
    }

    // MARK: - Internal: data operations

    internal func putInternal(entry: StorageEntry, excludeEngineId: ObjectIdentifier? = nil, excludeScope: NativeStorageScope? = nil) {
        storeQueue.sync(flags: .barrier) { store[entry.key] = entry.value }
        notifyChanged(entries: [entry], excludeEngineId: excludeEngineId, excludeScope: excludeScope)
    }

    internal func putAllInternal(entries: [StorageEntry], excludeEngineId: ObjectIdentifier? = nil, excludeScope: NativeStorageScope? = nil) {
        storeQueue.sync(flags: .barrier) {
            for e in entries { store[e.key] = e.value }
        }
        notifyChanged(entries: entries, excludeEngineId: excludeEngineId, excludeScope: excludeScope)
    }

    internal func getInternal(key: String) -> StorageEntry? {
        return storeQueue.sync {
            guard let value = store[key] else { return nil }
            return StorageEntry(key: key, value: value)
        }
    }

    internal func getByPrefixInternal(prefix: String) -> [StorageEntry] {
        return storeQueue.sync {
            store.compactMap { key, value in
                key.hasPrefix(prefix) ? StorageEntry(key: key, value: value) : nil
            }
        }
    }

    internal func removeInternal(key: String, excludeEngineId: ObjectIdentifier? = nil, excludeScope: NativeStorageScope? = nil) -> Bool {
        let removed: Bool = storeQueue.sync(flags: .barrier) {
            store.removeValue(forKey: key) != nil
        }
        if removed {
            notifyChanged(entries: [StorageEntry(key: key, value: "")], excludeEngineId: excludeEngineId, excludeScope: excludeScope)
        }
        return removed
    }

    internal func removeByPrefixInternal(prefix: String, excludeEngineId: ObjectIdentifier? = nil, excludeScope: NativeStorageScope? = nil) {
        var removedEntries: [StorageEntry] = []
        storeQueue.sync(flags: .barrier) {
            for key in store.keys where key.hasPrefix(prefix) {
                store.removeValue(forKey: key)
                removedEntries.append(StorageEntry(key: key, value: ""))
            }
        }
        if !removedEntries.isEmpty {
            notifyChanged(entries: removedEntries, excludeEngineId: excludeEngineId, excludeScope: excludeScope)
        }
    }

    internal func getAllInternal() -> [StorageEntry] {
        return storeQueue.sync {
            store.map { StorageEntry(key: $0.key, value: $0.value) }
        }
    }

    internal func clearInternal(excludeEngineId: ObjectIdentifier? = nil, excludeScope: NativeStorageScope? = nil) {
        let allEntries: [StorageEntry] = storeQueue.sync(flags: .barrier) {
            let entries = store.keys.map { StorageEntry(key: $0, value: "") }
            store.removeAll()
            return entries
        }
        notifyChanged(entries: allEntries, excludeEngineId: excludeEngineId, excludeScope: excludeScope)
    }

    // MARK: - Change notification dispatch

    private func notifyChanged(
        entries: [StorageEntry],
        excludeEngineId: ObjectIdentifier? = nil,
        excludeScope: NativeStorageScope? = nil
    ) {
        let event = StorageChangeEvent(entries: entries)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.flutterApisLock.lock()
            let apis = self.flutterApis
            self.flutterApisLock.unlock()

            for (id, api) in apis {
                if id == excludeEngineId { continue }
                api.onStorageChanged(event: event) { _ in /* fire-and-forget */ }
            }

            self.nativeScopesLock.lock()
            let scopes = self.nativeScopes
            self.nativeScopesLock.unlock()

            for scope in scopes {
                if scope === excludeScope { continue }
                scope.deliverChange(entries: entries)
            }
        }
    }
}

// MARK: - Per-engine Pigeon proxy

/// Implements the Pigeon `KeyValueStorageHostApi` for a single Flutter engine.
/// Each engine gets its own proxy so that writes from that engine are tagged
/// with its `engineId` for self-suppression.
private class EngineProxy: KeyValueStorageHostApi {

    private let impl: KeyValueStorageImpl
    private let engineId: ObjectIdentifier

    init(impl: KeyValueStorageImpl, engineId: ObjectIdentifier) {
        self.impl = impl
        self.engineId = engineId
    }

    func put(entry: StorageEntry) throws {
        impl.putInternal(entry: entry, excludeEngineId: engineId)
    }

    func putAll(entries: [StorageEntry]) throws {
        impl.putAllInternal(entries: entries, excludeEngineId: engineId)
    }

    func get(key: String) throws -> StorageEntry? {
        impl.getInternal(key: key)
    }

    func getByPrefix(prefix: String) throws -> [StorageEntry] {
        impl.getByPrefixInternal(prefix: prefix)
    }

    func remove(key: String) throws -> Bool {
        impl.removeInternal(key: key, excludeEngineId: engineId)
    }

    func removeByPrefix(prefix: String) throws {
        impl.removeByPrefixInternal(prefix: prefix, excludeEngineId: engineId)
    }

    func getAll() throws -> [StorageEntry] {
        impl.getAllInternal()
    }

    func clear() throws {
        impl.clearInternal(excludeEngineId: engineId)
    }
}
