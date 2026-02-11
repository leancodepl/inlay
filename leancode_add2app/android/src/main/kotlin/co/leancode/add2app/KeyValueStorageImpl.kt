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
 * Design decisions:
 * - **Self-notification suppression**: when a write originates from a specific
 *   source (a Flutter engine or an Android observer), that source is *not*
 *   notified back about its own change.
 * - **Main-thread dispatch**: all observer callbacks (Flutter and Android) are
 *   posted to the main looper so consumers never need `runOnUiThread`.
 * - **Thread-safe store**: [ConcurrentHashMap] for the data, synchronized
 *   blocks for the observer registries.
 */
object KeyValueStorageImpl : KeyValueStorageHostApi {

    // ── Data store ───────────────────────────────────────────────────────

    private val store = ConcurrentHashMap<String, String>()

    // ── Flutter engine registry ──────────────────────────────────────────

    private val flutterApis = mutableMapOf<Int, KeyValueStorageFlutterApi>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val callingEngineId = ThreadLocal<Int>()

    // ── Android observer registry ────────────────────────────────────────

    fun interface AndroidStorageObserver {
        fun onStorageChanged(entries: List<StorageEntry>)
    }

    private val androidObservers = mutableMapOf<Int, AndroidStorageObserver>()

    // ── Engine lifecycle ─────────────────────────────────────────────────

    fun attachToEngine(engine: FlutterEngine) {
        val engineId = System.identityHashCode(engine)
        val proxy = object : KeyValueStorageHostApi {
            private fun <T> withOrigin(block: () -> T): T {
                callingEngineId.set(engineId)
                try { return block() } finally { callingEngineId.remove() }
            }
            override fun put(entry: StorageEntry) = withOrigin { this@KeyValueStorageImpl.put(entry) }
            override fun putAll(entries: List<StorageEntry>) = withOrigin { this@KeyValueStorageImpl.putAll(entries) }
            override fun get(key: String) = this@KeyValueStorageImpl.get(key)
            override fun getByPrefix(prefix: String) = this@KeyValueStorageImpl.getByPrefix(prefix)
            override fun remove(key: String) = withOrigin { this@KeyValueStorageImpl.remove(key) }
            override fun removeByPrefix(prefix: String) = withOrigin { this@KeyValueStorageImpl.removeByPrefix(prefix) }
            override fun getAll() = this@KeyValueStorageImpl.getAll()
            override fun clear() = withOrigin { this@KeyValueStorageImpl.clear() }
        }
        KeyValueStorageHostApi.setUp(engine.dartExecutor.binaryMessenger, proxy)
        val flutterApi = KeyValueStorageFlutterApi(engine.dartExecutor.binaryMessenger)
        synchronized(flutterApis) { flutterApis[engineId] = flutterApi }
    }

    fun detachFromEngine(engine: FlutterEngine) {
        val engineId = System.identityHashCode(engine)
        KeyValueStorageHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        synchronized(flutterApis) { flutterApis.remove(engineId) }
    }

    fun addAndroidObserver(observer: AndroidStorageObserver): Int {
        val id = System.identityHashCode(observer)
        synchronized(androidObservers) { androidObservers[id] = observer }
        return id
    }

    fun removeAndroidObserver(observerId: Int) {
        synchronized(androidObservers) { androidObservers.remove(observerId) }
    }

    // ── HostApi implementation ───────────────────────────────────────────

    override fun put(entry: StorageEntry) {
        store[entry.key] = entry.value
        notifyChanged(listOf(entry))
    }

    override fun putAll(entries: List<StorageEntry>) {
        for (e in entries) store[e.key] = e.value
        notifyChanged(entries)
    }

    override fun get(key: String): StorageEntry? {
        val value = store[key] ?: return null
        return StorageEntry(key, value)
    }

    override fun getByPrefix(prefix: String): List<StorageEntry> {
        return store.entries
            .filter { it.key.startsWith(prefix) }
            .map { StorageEntry(it.key, it.value) }
    }

    override fun remove(key: String): Boolean {
        val removed = store.remove(key) != null
        if (removed) notifyChanged(listOf(StorageEntry(key, "")))
        return removed
    }

    override fun removeByPrefix(prefix: String) {
        val removedEntries = mutableListOf<StorageEntry>()
        val iter = store.entries.iterator()
        while (iter.hasNext()) {
            val e = iter.next()
            if (e.key.startsWith(prefix)) { iter.remove(); removedEntries.add(StorageEntry(e.key, "")) }
        }
        if (removedEntries.isNotEmpty()) notifyChanged(removedEntries)
    }

    override fun getAll(): List<StorageEntry> {
        return store.entries.map { StorageEntry(it.key, it.value) }
    }

    override fun clear() {
        val allKeys = store.keys().toList()
        store.clear()
        notifyChanged(allKeys.map { StorageEntry(it, "") })
    }

    // ── Direct access for Android code ───────────────────────────────────

    fun putFromAndroid(key: String, value: String, excludeObserver: Int? = null) {
        val old = store.put(key, value)
        if (old == value) return
        notifyChanged(listOf(StorageEntry(key, value)), excludeAndroidObserver = excludeObserver)
    }

    fun getFromAndroid(key: String): String? = store[key]

    // ── Change notification dispatch ─────────────────────────────────────

    private fun notifyChanged(
        entries: List<StorageEntry>,
        excludeAndroidObserver: Int? = null
    ) {
        val event = StorageChangeEvent(entries)
        val originEngineId = callingEngineId.get()

        mainHandler.post {
            synchronized(flutterApis) {
                for ((id, api) in flutterApis) {
                    if (id == originEngineId) continue
                    api.onStorageChanged(event) { /* fire-and-forget */ }
                }
            }

            synchronized(androidObservers) {
                for ((id, observer) in androidObservers) {
                    if (id == excludeAndroidObserver) continue
                    observer.onStorageChanged(entries)
                }
            }
        }
    }
}
