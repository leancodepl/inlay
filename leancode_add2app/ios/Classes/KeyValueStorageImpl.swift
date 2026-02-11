import Foundation
import Flutter

// MARK: - Native observer protocol

/// Protocol for native iOS code to observe storage changes.
/// Equivalent of Android's `KeyValueStorageImpl.AndroidStorageObserver`.
protocol NativeStorageObserver: AnyObject {
    func onStorageChanged(entries: [StorageEntry])
}

// MARK: - KeyValueStorageImpl

/// Framework-level key-value storage backed by an in-memory dictionary.
///
/// Single source of truth that bridges iOS native code and any number of
/// Flutter engine isolates (engine group).
///
/// Design decisions (mirrors Android `KeyValueStorageImpl`):
/// - **Self-notification suppression**: when a write originates from a specific
///   source (a Flutter engine or a native observer), that source is *not*
///   notified back about its own change.
/// - **Main-thread dispatch**: all observer callbacks (Flutter and native) are
///   dispatched on the main queue so consumers never need `DispatchQueue.main`.
/// - **Thread-safe store**: reads/writes are serialised on a private queue;
///   observer registries are protected by `NSLock`.
final class KeyValueStorageImpl: NSObject, KeyValueStorageHostApi {

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

    private let callingEngineIdKey = "co.leancode.add2app.KeyValueStorage.callingEngineId"

    // MARK: - Native observer registry

    private struct WeakObserver {
        weak var observer: NativeStorageObserver?
    }

    private var nativeObservers: [Int: WeakObserver] = [:]
    private let nativeObserversLock = NSLock()

    // MARK: - Engine lifecycle

    func attachToEngine(_ engine: FlutterEngine) {
        let engineId = ObjectIdentifier(engine)
        let messenger = engine.binaryMessenger

        let proxy = KeyValueStorageHostApiProxy(impl: self, engineId: engineId)
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

    // MARK: - Native observer registration

    @discardableResult
    func addNativeObserver(_ observer: NativeStorageObserver) -> Int {
        let id = ObjectIdentifier(observer).hashValue
        nativeObserversLock.lock()
        nativeObservers[id] = WeakObserver(observer: observer)
        nativeObserversLock.unlock()
        return id
    }

    func removeNativeObserver(_ observerId: Int) {
        nativeObserversLock.lock()
        nativeObservers.removeValue(forKey: observerId)
        nativeObserversLock.unlock()
    }

    // MARK: - HostApi implementation

    func put(entry: StorageEntry) throws {
        storeQueue.sync(flags: .barrier) { store[entry.key] = entry.value }
        notifyChanged(entries: [entry])
    }

    func putAll(entries: [StorageEntry]) throws {
        storeQueue.sync(flags: .barrier) {
            for e in entries { store[e.key] = e.value }
        }
        notifyChanged(entries: entries)
    }

    func get(key: String) throws -> StorageEntry? {
        return storeQueue.sync {
            guard let value = store[key] else { return nil }
            return StorageEntry(key: key, value: value)
        }
    }

    func getByPrefix(prefix: String) throws -> [StorageEntry] {
        return storeQueue.sync {
            store.compactMap { key, value in
                key.hasPrefix(prefix) ? StorageEntry(key: key, value: value) : nil
            }
        }
    }

    func remove(key: String) throws -> Bool {
        let removed: Bool = storeQueue.sync(flags: .barrier) {
            store.removeValue(forKey: key) != nil
        }
        if removed {
            notifyChanged(entries: [StorageEntry(key: key, value: "")])
        }
        return removed
    }

    func removeByPrefix(prefix: String) throws {
        var removedEntries: [StorageEntry] = []
        storeQueue.sync(flags: .barrier) {
            for key in store.keys where key.hasPrefix(prefix) {
                store.removeValue(forKey: key)
                removedEntries.append(StorageEntry(key: key, value: ""))
            }
        }
        if !removedEntries.isEmpty {
            notifyChanged(entries: removedEntries)
        }
    }

    func getAll() throws -> [StorageEntry] {
        return storeQueue.sync {
            store.map { StorageEntry(key: $0.key, value: $0.value) }
        }
    }

    func clear() throws {
        let allEntries: [StorageEntry] = storeQueue.sync(flags: .barrier) {
            let entries = store.keys.map { StorageEntry(key: $0, value: "") }
            store.removeAll()
            return entries
        }
        notifyChanged(entries: allEntries)
    }

    // MARK: - Direct access for native iOS code

    func putFromNative(key: String, value: String, excludeObserver: Int? = nil) {
        let old: String? = storeQueue.sync(flags: .barrier) {
            let prev = store[key]
            store[key] = value
            return prev
        }
        guard old != value else { return }
        notifyChanged(
            entries: [StorageEntry(key: key, value: value)],
            excludeNativeObserver: excludeObserver
        )
    }

    func getFromNative(key: String) -> String? {
        return storeQueue.sync { store[key] }
    }

    // MARK: - Change notification dispatch

    fileprivate func setCallingEngineId(_ id: ObjectIdentifier?) {
        Thread.current.threadDictionary[callingEngineIdKey] = id
    }

    private var currentCallingEngineId: ObjectIdentifier? {
        Thread.current.threadDictionary[callingEngineIdKey] as? ObjectIdentifier
    }

    private func notifyChanged(
        entries: [StorageEntry],
        excludeNativeObserver: Int? = nil
    ) {
        let event = StorageChangeEvent(entries: entries)
        let originEngineId = currentCallingEngineId

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.flutterApisLock.lock()
            let apis = self.flutterApis
            self.flutterApisLock.unlock()

            for (id, api) in apis {
                if id == originEngineId { continue }
                api.onStorageChanged(event: event) { _ in /* fire-and-forget */ }
            }

            self.nativeObserversLock.lock()
            let observers = self.nativeObservers
            self.nativeObserversLock.unlock()

            for (id, weak) in observers {
                if id == excludeNativeObserver { continue }
                weak.observer?.onStorageChanged(entries: entries)
            }
        }
    }
}

// MARK: - Host API proxy (for self-notification suppression)

private class KeyValueStorageHostApiProxy: KeyValueStorageHostApi {

    private let impl: KeyValueStorageImpl
    private let engineId: ObjectIdentifier

    init(impl: KeyValueStorageImpl, engineId: ObjectIdentifier) {
        self.impl = impl
        self.engineId = engineId
    }

    private func withOrigin<T>(_ block: () throws -> T) rethrows -> T {
        impl.setCallingEngineId(engineId)
        defer { impl.setCallingEngineId(nil) }
        return try block()
    }

    func put(entry: StorageEntry) throws { try withOrigin { try impl.put(entry: entry) } }
    func putAll(entries: [StorageEntry]) throws { try withOrigin { try impl.putAll(entries: entries) } }
    func get(key: String) throws -> StorageEntry? { try impl.get(key: key) }
    func getByPrefix(prefix: String) throws -> [StorageEntry] { try impl.getByPrefix(prefix: prefix) }
    func remove(key: String) throws -> Bool { try withOrigin { try impl.remove(key: key) } }
    func removeByPrefix(prefix: String) throws { try withOrigin { try impl.removeByPrefix(prefix: prefix) } }
    func getAll() throws -> [StorageEntry] { try impl.getAll() }
    func clear() throws { try withOrigin { try impl.clear() } }
}
