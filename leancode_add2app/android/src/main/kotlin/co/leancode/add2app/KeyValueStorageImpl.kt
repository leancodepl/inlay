package co.leancode.add2app

import android.os.Handler
import android.os.Looper
import co.leancode.add2app.storage.KeyValueStorageFlutterApi
import co.leancode.add2app.storage.KeyValueStorageHostApi
import co.leancode.add2app.storage.StorageChangeEvent
import co.leancode.add2app.storage.StorageEntry
import io.flutter.embedding.engine.FlutterEngine
import java.util.concurrent.ConcurrentHashMap

/**
 * Framework-level key-value storage backed by an in-memory [ConcurrentHashMap].
 *
 * Single source of truth that bridges Android code and any number of Flutter
 * engine isolates (EngineGroup).
 *
 * ### Usage for native Android code
 *
 * Create a [NativeStorageScope] via [createScope] to read, write, and
 * optionally observe storage changes. Observation is opt-in via
 * [NativeStorageScope.startObserving] / [NativeStorageScope.stopObserving].
 * When observing, writes through the scope automatically suppress
 * self-notifications:
 *
 * ```kotlin
 * val storage = KeyValueStorageImpl.createScope()
 *
 * // Read / write (works immediately, no observer needed)
 * storage.put("key", "value")
 * val v = storage.get("key")
 *
 * // Optionally start observing
 * storage.startObserving { entries ->
 *     for (entry in entries) { /* react to external changes */ }
 * }
 *
 * storage.put("key", "value2")  // observer NOT called for own writes
 *
 * storage.stopObserving()       // stop receiving callbacks
 * storage.dispose()             // clean up
 * ```
 *
 * Design decisions:
 * - **Self-notification suppression**: when a write originates from a specific
 *   source (a Flutter engine or a native scope), that source is *not*
 *   notified back about its own change.
 * - **Main-thread dispatch**: all observer callbacks (Flutter and Android) are
 *   posted to the main looper so consumers never need `runOnUiThread`.
 * - **Thread-safe store**: [ConcurrentHashMap] for the data, synchronized
 *   blocks for the observer registries.
 */
object KeyValueStorageImpl {

    // ── Data store ───────────────────────────────────────────────────────

    private val store = ConcurrentHashMap<String, String>()

    // ── Flutter engine registry ──────────────────────────────────────────

    private val flutterApis = mutableMapOf<Int, KeyValueStorageFlutterApi>()
    private val mainHandler = Handler(Looper.getMainLooper())

    // ── Native scope (observer) registry ─────────────────────────────────

    private val nativeObservers = mutableListOf<NativeStorageScope>()

    // ── Engine lifecycle ─────────────────────────────────────────────────

    fun attachToEngine(engine: FlutterEngine) {
        val engineId = System.identityHashCode(engine)
        val proxy = EngineProxy(engineId)
        KeyValueStorageHostApi.setUp(engine.dartExecutor.binaryMessenger, proxy)
        val flutterApi = KeyValueStorageFlutterApi(engine.dartExecutor.binaryMessenger)
        synchronized(flutterApis) { flutterApis[engineId] = flutterApi }
    }

    fun detachFromEngine(engine: FlutterEngine) {
        val engineId = System.identityHashCode(engine)
        KeyValueStorageHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        synchronized(flutterApis) { flutterApis.remove(engineId) }
    }

    // ── Public API: scoped access for native Android code ────────────────

    /**
     * Create a [NativeStorageScope] for reading and writing storage.
     *
     * The scope can optionally observe changes via
     * [NativeStorageScope.startObserving]. Writes through the scope
     * automatically suppress the observer callback (self-notification
     * suppression).
     *
     * Call [NativeStorageScope.dispose] when you no longer need the scope
     * (e.g. in `onDestroy`, `onDispose`).
     */
    fun createScope(): NativeStorageScope {
        return NativeStorageScope()
    }

    // ── Internal: scope observer registration ────────────────────────────

    internal fun registerScope(scope: NativeStorageScope) {
        synchronized(nativeObservers) { nativeObservers.add(scope) }
    }

    internal fun unregisterScope(scope: NativeStorageScope) {
        synchronized(nativeObservers) { nativeObservers.removeAll { it === scope } }
    }

    // ── Internal: data operations ────────────────────────────────────────

    internal fun putInternal(entry: StorageEntry, excludeEngineId: Int? = null, excludeScope: NativeStorageScope? = null) {
        store[entry.key] = entry.value
        notifyChanged(listOf(entry), excludeEngineId, excludeScope)
    }

    internal fun putAllInternal(entries: List<StorageEntry>, excludeEngineId: Int? = null, excludeScope: NativeStorageScope? = null) {
        for (e in entries) store[e.key] = e.value
        notifyChanged(entries, excludeEngineId, excludeScope)
    }

    internal fun getInternal(key: String): StorageEntry? {
        val value = store[key] ?: return null
        return StorageEntry(key, value)
    }

    internal fun getByPrefixInternal(prefix: String): List<StorageEntry> {
        return store.entries
            .filter { it.key.startsWith(prefix) }
            .map { StorageEntry(it.key, it.value) }
    }

    internal fun removeInternal(key: String, excludeEngineId: Int? = null, excludeScope: NativeStorageScope? = null): Boolean {
        val removed = store.remove(key) != null
        if (removed) notifyChanged(listOf(StorageEntry(key, "")), excludeEngineId, excludeScope)
        return removed
    }

    internal fun removeByPrefixInternal(prefix: String, excludeEngineId: Int? = null, excludeScope: NativeStorageScope? = null) {
        val removedEntries = mutableListOf<StorageEntry>()
        val iter = store.entries.iterator()
        while (iter.hasNext()) {
            val e = iter.next()
            if (e.key.startsWith(prefix)) { iter.remove(); removedEntries.add(StorageEntry(e.key, "")) }
        }
        if (removedEntries.isNotEmpty()) notifyChanged(removedEntries, excludeEngineId, excludeScope)
    }

    internal fun getAllInternal(): List<StorageEntry> {
        return store.entries.map { StorageEntry(it.key, it.value) }
    }

    internal fun clearInternal(excludeEngineId: Int? = null, excludeScope: NativeStorageScope? = null) {
        val allKeys = store.keys().toList()
        store.clear()
        notifyChanged(allKeys.map { StorageEntry(it, "") }, excludeEngineId, excludeScope)
    }

    // ── Change notification dispatch ─────────────────────────────────────

    private fun notifyChanged(
        entries: List<StorageEntry>,
        excludeEngineId: Int? = null,
        excludeScope: NativeStorageScope? = null
    ) {
        val event = StorageChangeEvent(entries)

        mainHandler.post {
            synchronized(flutterApis) {
                for ((id, api) in flutterApis) {
                    if (id == excludeEngineId) continue
                    api.onStorageChanged(event) { /* fire-and-forget */ }
                }
            }

            synchronized(nativeObservers) {
                for (scope in nativeObservers) {
                    if (scope === excludeScope) continue
                    scope.deliverChange(entries)
                }
            }
        }
    }

    // ── Per-engine Pigeon proxy ──────────────────────────────────────────

    private class EngineProxy(private val engineId: Int) : KeyValueStorageHostApi {
        override fun put(entry: StorageEntry) = putInternal(entry, excludeEngineId = engineId)
        override fun putAll(entries: List<StorageEntry>) = putAllInternal(entries, excludeEngineId = engineId)
        override fun get(key: String) = getInternal(key)
        override fun getByPrefix(prefix: String) = getByPrefixInternal(prefix)
        override fun remove(key: String) = removeInternal(key, excludeEngineId = engineId)
        override fun removeByPrefix(prefix: String) = removeByPrefixInternal(prefix, excludeEngineId = engineId)
        override fun getAll() = getAllInternal()
        override fun clear() = clearInternal(excludeEngineId = engineId)
    }
}

// ── NativeStorageScope ───────────────────────────────────────────────────

/**
 * Scoped handle for native Android code to read, write, and optionally
 * observe [KeyValueStorageImpl].
 *
 * All write operations ([put], [putAll], [remove], [removeByPrefix], [clear])
 * automatically suppress the observer callback so you never receive
 * notifications about your own changes.
 *
 * Observation is opt-in:
 * - [startObserving] — register a callback for external changes.
 * - [stopObserving] — unregister the callback (read/write still works).
 * - [dispose] — stop observing and release the scope.
 *
 * Create via [KeyValueStorageImpl.createScope].
 */
class NativeStorageScope internal constructor() {

    private var onChange: ((List<StorageEntry>) -> Unit)? = null

    // ── Observation ──────────────────────────────────────────────────

    /**
     * Start observing storage changes from other sources (Flutter engines
     * or other native scopes). Replaces any previous observer.
     *
     * The [onChange] callback is invoked on the **main thread**.
     */
    fun startObserving(onChange: (List<StorageEntry>) -> Unit) {
        stopObserving()
        this.onChange = onChange
        KeyValueStorageImpl.registerScope(this)
    }

    /**
     * Stop observing. The scope remains usable for read/write; only the
     * observer callback is removed.
     */
    fun stopObserving() {
        if (onChange != null) {
            KeyValueStorageImpl.unregisterScope(this)
            onChange = null
        }
    }

    // ── Write (auto-suppressed) ──────────────────────────────────────

    fun put(key: String, value: String) {
        KeyValueStorageImpl.putInternal(StorageEntry(key, value), excludeScope = this)
    }

    fun putAll(entries: List<StorageEntry>) {
        KeyValueStorageImpl.putAllInternal(entries, excludeScope = this)
    }

    fun remove(key: String): Boolean {
        return KeyValueStorageImpl.removeInternal(key, excludeScope = this)
    }

    fun removeByPrefix(prefix: String) {
        KeyValueStorageImpl.removeByPrefixInternal(prefix, excludeScope = this)
    }

    fun clear() {
        KeyValueStorageImpl.clearInternal(excludeScope = this)
    }

    // ── Read ─────────────────────────────────────────────────────────

    fun get(key: String): String? {
        return KeyValueStorageImpl.getInternal(key)?.value
    }

    fun getAll(): List<StorageEntry> {
        return KeyValueStorageImpl.getAllInternal()
    }

    fun getByPrefix(prefix: String): List<StorageEntry> {
        return KeyValueStorageImpl.getByPrefixInternal(prefix)
    }

    // ── Internal: observer delivery ─────────────────────────────────

    internal fun deliverChange(entries: List<StorageEntry>) {
        onChange?.invoke(entries)
    }

    // ── Lifecycle ────────────────────────────────────────────────────

    fun dispose() {
        stopObserving()
    }
}
