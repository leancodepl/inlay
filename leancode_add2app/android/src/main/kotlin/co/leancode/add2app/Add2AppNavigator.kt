package co.leancode.add2app

import android.app.Activity
import android.content.Context
import android.content.Intent
import co.leancode.add2app.navigator.Add2AppNavigatorHostApi
import co.leancode.add2app.navigator.PageSettings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.FlutterEngineGroupCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.FlutterInjector

/**
 * Interface for handling native route requests dispatched from Flutter.
 *
 * The generated `NativeRouteHandler` abstract class implements this interface,
 * dispatching [PageSettings] to typed `on*` methods. Developers extend the
 * generated class rather than implementing this interface directly.
 */
fun interface NativeRouteHandler {
    fun handle(context: Context, route: PageSettings)
}

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
 * Add2AppNavigator.instance.push(SoundsNotificationsPage(contactId: '42'));
 * Add2AppNavigator.instance.pop();
 * ```
 *
 * Navigation from Flutter to native screens:
 * ```kotlin
 * // Set the generated native route handler (e.g. Application.onCreate)
 * Add2AppNavigator.setNativeRouteHandler(object : NativeRouteHandler() {
 *     override fun onNativeEditProfile(route: NativeEditProfileRoute, ctx: Context) { ... }
 *     override fun onNativeMediaViewer(route: NativeMediaViewerRoute, ctx: Context) { ... }
 * })
 * ```
 * ```dart
 * // From Flutter:
 * Add2AppNavigator.instance.pushNativeRoute(
 *   NativeEditProfilePage(contactId: '42').toPageSettings(),
 * );
 * ```
 *
 * The navigator automatically:
 * - Manages the [FlutterEngineGroup] singleton.
 * - Creates a generic [Add2AppFlutterActivity] (or [Add2AppFlutterFragment]) for every page.
 * - Registers the Pigeon HostApi on each engine so Flutter can push/pop too.
 * - Attaches [KeyValueStorageImpl] to each engine.
 */
object Add2AppNavigator {

    private const val ENGINE_GROUP_ID = "add2app_engine_group"
    private const val PREWARM_ROUTE_ID = "__add2app_prewarm__"

    /** The single Dart entrypoint used by all add2app pages. */
    private const val DART_ENTRYPOINT = "add2appMain"

    private lateinit var appContext: Context

    /** The single native route handler set by the app. */
    private var nativeRouteHandler: NativeRouteHandler? = null
    /** Whether [init] should prewarm a hidden engine. */
    private var isPrewarmEnabled: Boolean = true
    /** Hidden warm-up engine kept alive for app lifetime. */
    private var prewarmedEngine: FlutterEngine? = null

    // ── Initialisation ───────────────────────────────────────────────────

    /**
     * Call once at app startup (e.g. `Application.onCreate`).
     * Idempotent — safe to call multiple times.
     */
    @JvmOverloads
    fun init(context: Context, prewarm: Boolean = true) {
        appContext = context.applicationContext
        isPrewarmEnabled = prewarm
        ensureEngineGroup()
        if (isPrewarmEnabled) {
            prewarmEngineIfNeeded()
        }
    }

    /**
     * Enable/disable automatic prewarming performed by [init].
     *
     * Enabled by default.
     */
    @Synchronized
    fun setPrewarmEnabled(enabled: Boolean) {
        isPrewarmEnabled = enabled
        if (enabled) {
            if (::appContext.isInitialized) {
                prewarmEngineIfNeeded()
            }
        } else {
            destroyPrewarmedEngine()
        }
    }

    /**
     * Imperatively prewarm the hidden engine.
     */
    fun prewarm(context: Context) {
        init(context, prewarm = isPrewarmEnabled)
        prewarmEngineIfNeeded()
    }

    /**
     * Destroy the hidden prewarmed engine and release its resources.
     */
    @Synchronized
    fun destroyPrewarmedEngine() {
        val engine = prewarmedEngine ?: return
        Add2AppNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        KeyValueStorageImpl.detachFromEngine(engine)
        engine.destroy()
        prewarmedEngine = null
    }

    private fun ensureEngineGroup() {
        if (!FlutterEngineGroupCache.getInstance().contains(ENGINE_GROUP_ID)) {
            FlutterEngineGroupCache.getInstance()
                .put(ENGINE_GROUP_ID, FlutterEngineGroup(appContext))
        }
    }

    /**
     * Boots a hidden engine once so first visible add2app navigation is faster.
     */
    @Synchronized
    private fun prewarmEngineIfNeeded() {
        if (prewarmedEngine != null) return

        val engine = FlutterEngine(appContext)
        engine.navigationChannel.setInitialRoute(PREWARM_ROUTE_ID)
        val bundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
        val entrypoint = DartExecutor.DartEntrypoint(bundlePath, DART_ENTRYPOINT)
        engine.dartExecutor.executeDartEntrypoint(entrypoint)

        // The Dart entrypoint initializes Add2App services, so we must register
        // HostApi + storage even for a hidden warm-up engine.
        Add2AppNavigatorHostApi.setUp(
            engine.dartExecutor.binaryMessenger,
            object : Add2AppNavigatorHostApi {
                override fun push(page: PageSettings) {}
                override fun pop() {}
                override fun pushNativeRoute(route: PageSettings) {}
            }
        )
        KeyValueStorageImpl.attachToEngine(engine)
        prewarmedEngine = engine
    }

    // ── Public API (Android side) ────────────────────────────────────────

    /**
     * Push a new Flutter Activity that displays the page described by [page].
     *
     * This is the **only** method Android code needs to call.
     * No FlutterEngine, no entrypoints, no method channels.
     */
    fun push(context: Context, page: PageSettings) {
        init(context, prewarm = isPrewarmEnabled)
        context.startActivity(createIntent(context, page))
    }

    /**
     * Convenience overload that builds [PageSettings] from primitives.
     */
    fun push(context: Context, routeId: String, params: Map<String, String>? = null) {
        push(context, PageSettings(routeId, params))
    }

    // ── Native route handler ────────────────────────────────────────────

    /**
     * Set the native route handler that processes Flutter → native navigation.
     *
     * Typically you pass an instance of the generated `NativeRouteHandler`
     * subclass. The generated base class dispatches `PageSettings` to typed
     * `on*` methods — you only implement those.
     *
     * ```kotlin
     * // In Application.onCreate:
     * Add2AppNavigator.setNativeRouteHandler(object : NativeRouteHandler() {
     *     override fun onNativeEditProfile(route: NativeEditProfileRoute, context: Context) {
     *         context.startActivity(Intent(context, EditProfileActivity::class.java).apply {
     *             putExtra("contactId", route.contactId)
     *         })
     *     }
     *     override fun onNativeMediaViewer(route: NativeMediaViewerRoute, context: Context) {
     *         context.startActivity(Intent(context, MediaViewerActivity::class.java))
     *     }
     * })
     * ```
     */
    fun setNativeRouteHandler(handler: NativeRouteHandler) {
        nativeRouteHandler = handler
    }

    /**
     * Dispatch a native route request. Called by the Pigeon HostApi impl.
     * Throws if no handler has been set.
     */
    internal fun dispatchNativeRoute(context: Context, route: PageSettings) {
        val handler = nativeRouteHandler
            ?: throw IllegalStateException(
                "No native route handler set. " +
                "Call Add2AppNavigator.setNativeRouteHandler() in your Application.onCreate()."
            )
        handler.handle(context, route)
    }

    // ── Fragment factory ──────────────────────────────────────────────────

    /**
     * Create an [Add2AppFlutterFragment] configured to display the page
     * described by [page].
     *
     * The returned fragment can be added to any Activity via a
     * FragmentTransaction:
     * ```kotlin
     * val fragment = Add2AppNavigator.createFragment(context, page)
     * supportFragmentManager.beginTransaction()
     *     .replace(R.id.container, fragment)
     *     .commit()
     * ```
     *
     * Engine configuration (Pigeon APIs, storage) is set up automatically
     * when the fragment attaches — no manual wiring needed.
     */
    fun createFragment(context: Context, page: PageSettings): Add2AppFlutterFragment {
        init(context, prewarm = isPrewarmEnabled)
        val initialRoute = encodePageSettings(page)
        return FlutterFragment.NewEngineInGroupFragmentBuilder(
            Add2AppFlutterFragment::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(DART_ENTRYPOINT)
            .initialRoute(initialRoute)
            .build<Add2AppFlutterFragment>()
    }

    // ── Intent factory ───────────────────────────────────────────────────

    internal fun createIntent(context: Context, page: PageSettings): Intent {
        init(context, prewarm = isPrewarmEnabled)
        val initialRoute = encodePageSettings(page)
        return FlutterActivity.NewEngineInGroupIntentBuilder(
            Add2AppFlutterActivity::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(DART_ENTRYPOINT)
            .initialRoute(initialRoute)
            .build(context)
    }

    // ── Engine configuration (called by Add2AppFlutterActivity / Fragment) ─

    /**
     * Called by [Add2AppFlutterActivity.configureFlutterEngine] and
     * [Add2AppFlutterFragment.configureFlutterEngine].
     * Registers Pigeon APIs + storage on the engine.
     *
     * @param onPop optional override for the pop behaviour. When `null`
     *   (the default), `activity.finish()` is called. Supply a custom
     *   lambda to integrate with Compose Navigation, Fragment back stack,
     *   or any other navigation mechanism.
     */
    internal fun configureEngine(
        engine: FlutterEngine,
        activity: Activity,
        onPop: (() -> Unit)? = null,
    ) {
        val hostApi = object : Add2AppNavigatorHostApi {
            override fun push(page: PageSettings) {
                activity.startActivity(createIntent(activity, page))
            }
            override fun pop() {
                onPop?.invoke() ?: activity.finish()
            }
            override fun pushNativeRoute(route: PageSettings) {
                dispatchNativeRoute(activity, route)
            }
        }
        Add2AppNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, hostApi)
        KeyValueStorageImpl.attachToEngine(engine)
    }

    /**
     * Called by [Add2AppFlutterActivity.cleanUpFlutterEngine] and
     * [Add2AppFlutterFragment.cleanUpFlutterEngine].
     */
    internal fun cleanUpEngine(engine: FlutterEngine) {
        Add2AppNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        KeyValueStorageImpl.detachFromEngine(engine)
    }

    // ── Encoding ─────────────────────────────────────────────────────────

    internal fun encodePageSettings(page: PageSettings): String {
        val params = page.params
        if (params == null) return page.routeId

        // Flutter pages use Map<String, String> params — URL-encode them.
        if (params is Map<*, *>) {
            val mapParams = params.filterValues { it != null }
            if (mapParams.isEmpty()) return page.routeId
            val query = mapParams.entries.joinToString("&") {
                "${Uri.encode(it.key.toString())}=${Uri.encode(it.value.toString())}"
            }
            return "${page.routeId}?$query"
        }

        // Native pages carry pigeon-encoded List params — no URL encoding.
        return page.routeId
    }

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

    private object Uri {
        fun encode(s: String): String = java.net.URLEncoder.encode(s, "UTF-8")
        fun decode(s: String): String = java.net.URLDecoder.decode(s, "UTF-8")
    }
}
