package org.thoughtcrime.securesms.flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import co.leancode.signal_module.navigator.Add2AppNavigatorHostApi
import co.leancode.signal_module.navigator.PageSettings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.FlutterEngineGroupCache

/**
 * Framework-level navigator that hides all Flutter internals
 * (FlutterEngine, FlutterEngineGroup, FlutterActivity, method channels)
 * from the developer.
 *
 * Usage from Android:
 * ```kotlin
 * // One-time setup (e.g. Application.onCreate)
 * Add2AppNavigator.init(applicationContext)
 *
 * // Navigate to a Flutter page from any Activity/Fragment
 * Add2AppNavigator.push(context, PageSettings("soundsNotifications", mapOf("contactId" to "42")))
 * ```
 *
 * Usage from Flutter (via Pigeon-generated [Add2AppNavigatorHostApi]):
 * ```dart
 * final nav = Add2AppNavigator();
 * nav.push(SoundsNotificationsPageSettings(contactId: '42'));
 * nav.pop();
 * ```
 *
 * The navigator automatically:
 * - Manages the [FlutterEngineGroup] singleton.
 * - Creates a generic [Add2AppFlutterActivity] for every push.
 * - Registers the Pigeon HostApi on each engine so Flutter can push/pop too.
 * - Attaches [KeyValueStorageImpl] to each engine.
 */
object Add2AppNavigator {

    private const val ENGINE_GROUP_ID = "add2app_engine_group"

    /** The single Dart entrypoint used by all add2app pages. */
    private const val DART_ENTRYPOINT = "add2appMain"

    private lateinit var appContext: Context

    // ── Initialisation ───────────────────────────────────────────────────

    /**
     * Call once at app startup (e.g. `Application.onCreate`).
     * Idempotent — safe to call multiple times.
     */
    fun init(context: Context) {
        appContext = context.applicationContext
        ensureEngineGroup()
    }

    private fun ensureEngineGroup() {
        if (!FlutterEngineGroupCache.getInstance().contains(ENGINE_GROUP_ID)) {
            FlutterEngineGroupCache.getInstance()
                .put(ENGINE_GROUP_ID, FlutterEngineGroup(appContext))
        }
    }

    // ── Public API (Android side) ────────────────────────────────────────

    /**
     * Push a new Flutter Activity that displays the page described by [page].
     *
     * This is the **only** method Android code needs to call.
     * No FlutterEngine, no entrypoints, no method channels.
     */
    fun push(context: Context, page: PageSettings) {
        init(context)
        context.startActivity(createIntent(context, page))
    }

    /**
     * Convenience overload that builds [PageSettings] from primitives.
     */
    fun push(context: Context, routeId: String, params: Map<String, String>? = null) {
        push(context, PageSettings(routeId, params))
    }

    // ── Intent factory ───────────────────────────────────────────────────

    internal fun createIntent(context: Context, page: PageSettings): Intent {
        init(context)
        // Encode PageSettings into the initial route so the Dart entrypoint
        // can decode it without any extra channel call.
        val initialRoute = encodePageSettings(page)
        return FlutterActivity.NewEngineInGroupIntentBuilder(
            Add2AppFlutterActivity::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(DART_ENTRYPOINT)
            .initialRoute(initialRoute)
            .build(context)
    }

    // ── Engine configuration (called by Add2AppFlutterActivity) ──────────

    /**
     * Called by [Add2AppFlutterActivity.configureFlutterEngine].
     * Registers Pigeon APIs + storage on the engine.
     */
    internal fun configureEngine(engine: FlutterEngine, activity: Activity) {
        // Register navigation HostApi so Flutter can push/pop.
        val hostApi = object : Add2AppNavigatorHostApi {
            override fun push(page: PageSettings) {
                activity.startActivity(createIntent(activity, page))
            }
            override fun pop() {
                activity.finish()
            }
        }
        Add2AppNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, hostApi)

        // Attach key-value storage.
        KeyValueStorageImpl.attachToEngine(engine)
    }

    /**
     * Called by [Add2AppFlutterActivity.cleanUpFlutterEngine].
     */
    internal fun cleanUpEngine(engine: FlutterEngine) {
        Add2AppNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        KeyValueStorageImpl.detachFromEngine(engine)
    }

    // ── Encoding ─────────────────────────────────────────────────────────

    /**
     * Encode [PageSettings] into a single string suitable for `initialRoute`.
     * Format: `routeId?key1=value1&key2=value2`
     */
    internal fun encodePageSettings(page: PageSettings): String {
        val params = page.params
        if (params.isNullOrEmpty()) return page.routeId
        val query = params.entries.joinToString("&") { "${Uri.encode(it.key)}=${Uri.encode(it.value)}" }
        return "${page.routeId}?$query"
    }

    /** Decode the `initialRoute` string back into [PageSettings]. */
    internal fun decodePageSettings(initialRoute: String): PageSettings {
        val questionMark = initialRoute.indexOf('?')
        if (questionMark < 0) return PageSettings(initialRoute, null)
        val routeId = initialRoute.substring(0, questionMark)
        val queryString = initialRoute.substring(questionMark + 1)
        val params = mutableMapOf<String, String>()
        for (pair in queryString.split("&")) {
            val eq = pair.indexOf('=')
            if (eq > 0) {
                params[Uri.decode(pair.substring(0, eq))] = Uri.decode(pair.substring(eq + 1))
            }
        }
        return PageSettings(routeId, params)
    }

    // URI encoding helpers (avoid pulling in java.net.URLEncoder)
    private object Uri {
        fun encode(s: String): String = java.net.URLEncoder.encode(s, "UTF-8")
        fun decode(s: String): String = java.net.URLDecoder.decode(s, "UTF-8")
    }
}
