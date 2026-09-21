package co.leancode.inlay

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import co.leancode.inlay.navigator.InlayNavigatorHostApi
import co.leancode.inlay.navigator.PageSettings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.FlutterEngineGroupCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.FlutterInjector
import io.flutter.plugin.common.StandardMessageCodec
import androidx.fragment.app.FragmentActivity
import java.nio.ByteBuffer

/**
 * Interface for handling native route requests dispatched from Flutter.
 *
 * The generated `NativeRouteHandler` abstract class implements this interface,
 * dispatching [PageSettings] to typed `on*` methods. Developers extend the
 * generated class rather than implementing this interface directly.
 */
fun interface NativeRouteHandler {
    /**
     * [completion] must be invoked exactly once with the screen's result
     * (`null` for routes without one) - it completes the awaiting Dart
     * future when the route was pushed via `pushForResult()`.
     */
    fun handle(context: Context, route: PageSettings, completion: (Any?) -> Unit)
}

/**
 * Framework-level navigator that hides all Flutter internals
 * (FlutterEngine, FlutterEngineGroup, FlutterActivity, method channels)
 * from the developer.
 *
 * Usage from Android:
 * ```kotlin
 * // One-time setup (e.g. Application.onCreate)
 * InlayNavigator.init(applicationContext)
 *
 * // Navigate to a Flutter page from any Activity/Fragment
 * InlayNavigator.push(context, PageSettings("soundsNotifications", mapOf("contactId" to "42")))
 * ```
 *
 * Usage from Flutter (via Pigeon-generated [InlayNavigatorHostApi]):
 * ```dart
 * InlayNavigator.instance.push(SoundsNotificationsPage(contactId: '42'));
 * InlayNavigator.instance.pop();
 * ```
 *
 * Navigation from Flutter to native screens:
 * ```kotlin
 * // Set the generated native route handler (e.g. Application.onCreate)
 * InlayNavigator.setNativeRouteHandler(object : NativeRouteHandler() {
 *     override fun onNativeEditProfile(route: NativeEditProfileRoute, ctx: Context) { ... }
 *     override fun onNativeMediaViewer(route: NativeMediaViewerRoute, ctx: Context) { ... }
 * })
 * ```
 * ```dart
 * // From Flutter:
 * InlayNavigator.instance.pushNativeRoute(
 *   NativeEditProfilePage(contactId: '42').toPageSettings(),
 * );
 * ```
 *
 * The navigator automatically:
 * - Manages the [FlutterEngineGroup] singleton.
 * - Creates a generic [InlayFlutterActivity] (or [InlayFlutterFragment]) for every page.
 * - Registers the Pigeon HostApi on each engine so Flutter can push/pop too.
 * - Attaches [KeyValueStorageImpl] to each engine.
 */
object InlayNavigator {

    private const val ENGINE_GROUP_ID = "inlay_engine_group"
    private const val PREWARM_ROUTE_ID = "__inlay_prewarm__"

    /** The Dart entrypoint used by all inlay pages. Defaults to `inlayMain`. */
    @Volatile
    var dartEntrypoint: String = "inlayMain"
        private set

    private lateinit var appContext: Context

    /** The single native route handler set by the app. */
    private var nativeRouteHandler: NativeRouteHandler? = null
    /** Per-engine setup hook invoked once for every engine used by inlay pages. */
    @Volatile
    private var onEngineCreated: ((FlutterEngine) -> Unit)? = null
    /** Whether [init] should prewarm a hidden engine. */
    var isPrewarmEnabled: Boolean = true
        private set
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
     * Register the shared [FlutterEngineGroup] in the cache without prewarming
     * or changing the prewarm setting. Idempotent and cheap.
     *
     * [InlayFlutterActivity] and [InlayFlutterFragment] call this before the
     * Flutter embedding resolves the cached engine group, so a container
     * restored from saved state (process death, config change) works even
     * when the app initializes inlay lazily instead of in
     * `Application.onCreate` - without it the embedding throws
     * `IllegalStateException` for the missing group. Host code only needs
     * it for its own `FlutterFragment` subclasses built on inlay's engine
     * group; call it from the Activity's `onCreate` **before** `super.onCreate`.
     */
    fun ensureInitialized(context: Context) {
        appContext = context.applicationContext
        ensureEngineGroup()
    }

    /**
     * Set a callback invoked exactly once for every [FlutterEngine] used by
     * inlay pages — including the hidden prewarmed engine — right after the
     * engine is created and before Flutter content is shown.
     *
     * Unlike iOS, plugins register automatically on Android: the Flutter
     * embedding invokes `GeneratedPluginRegistrant` on every engine, so do
     * **not** register plugins here (they would register twice). Use this
     * hook for any additional per-engine native setup, e.g. attaching
     * custom platform channels or platform view factories.
     *
     * If the prewarmed engine already exists when the callback is set, the
     * callback is invoked on it immediately.
     */
    @Synchronized
    fun setOnEngineCreated(callback: ((FlutterEngine) -> Unit)?) {
        onEngineCreated = callback
        prewarmedEngine?.let { callback?.invoke(it) }
    }

    /**
     * Change the Dart entrypoint used for every engine inlay creates.
     *
     * The entrypoint must be a top-level function in the Flutter module
     * annotated with `@pragma('vm:entry-point')`. Engines that are already
     * running keep their entrypoint; the hidden prewarmed engine is
     * recreated so the next navigation uses the new one.
     */
    @Synchronized
    fun setDartEntrypoint(entrypoint: String) {
        if (entrypoint == dartEntrypoint) return
        dartEntrypoint = entrypoint
        if (prewarmedEngine != null) {
            destroyPrewarmedEngine()
            if (isPrewarmEnabled && ::appContext.isInitialized) {
                prewarmEngineIfNeeded()
            }
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
        InlayNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
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
     * Boots a hidden engine once so first visible inlay navigation is faster.
     *
     * The engine is created **from the [FlutterEngineGroup]** so it initialises
     * the shared Dart VM snapshot. Subsequent engines in the same group then
     * skip that work and start much faster.
     */
    @Synchronized
    private fun prewarmEngineIfNeeded() {
        if (prewarmedEngine != null) return

        val engineGroup = FlutterEngineGroupCache.getInstance().get(ENGINE_GROUP_ID) ?: return
        val bundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
        val entrypoint = DartExecutor.DartEntrypoint(bundlePath, dartEntrypoint)
        val engine = engineGroup.createAndRunEngine(appContext, entrypoint, PREWARM_ROUTE_ID)
        onEngineCreated?.invoke(engine)

        InlayNavigatorHostApi.setUp(
            engine.dartExecutor.binaryMessenger,
            object : InlayNavigatorHostApi {
                override fun push(page: PageSettings) {}
                override fun pushForResult(page: PageSettings, callback: (Result<Any?>) -> Unit) {
                    callback(Result.success(null))
                }
                override fun pop(result: Any?) {}
                override fun pushNativeRoute(route: PageSettings) {}
                override fun pushNativeRouteForResult(route: PageSettings, callback: (Result<Any?>) -> Unit) {
                    callback(Result.success(null))
                }
                override fun setNativePopGestureEnabled(enabled: Boolean) {}
                override fun getInitialRouteData(): PageSettings? = null
                override fun presentDialog(page: PageSettings) {}
                override fun presentDialogForResult(page: PageSettings, callback: (Result<Any?>) -> Unit) {
                    callback(Result.success(null))
                }
            }
        )
        KeyValueStorageImpl.attachToEngine(engine)
        prewarmedEngine = engine
    }

    // ── Public API (Android side) ────────────────────────────────────────

    /**
     * Push a new Flutter Activity that displays the page described by [route].
     *
     * This is the **only** method Android code needs to call.
     * No FlutterEngine, no entrypoints, no method channels.
     *
     * ```kotlin
     * InlayNavigator.push(context, SoundsNotificationsPage(contactId = "42"))
     * ```
     */
    fun push(context: Context, route: FlutterRoute) {
        init(context, prewarm = isPrewarmEnabled)
        context.startActivity(createIntent(context, route.toPageSettings()))
    }

    /**
     * Push a Flutter screen that returns a typed result.
     *
     * [onResult] is invoked exactly once - with the decoded result the
     * screen pops with, or `null` when it is dismissed without one. The
     * callback lives in process memory: if the process is killed while the
     * Flutter screen is open, it is not restored.
     *
     * ```kotlin
     * InlayNavigator.push(context, CounterPage()) { count -> ... } // count: Long?
     * ```
     */
    fun <R : Any> push(
        context: Context,
        route: FlutterRouteWithResult<R>,
        onResult: (R?) -> Unit,
    ) {
        init(context, prewarm = isPrewarmEnabled)
        val intent = createIntent(context, route.toPageSettings())
        intent.putExtra(
            EXTRA_RESULT_ID,
            registerResultCallback { raw -> onResult(route.decodeResult(raw)) },
        )
        context.startActivity(intent)
    }

    // ── Result plumbing ──────────────────────────────────────────────────

    private val pendingResultCallbacks = mutableMapOf<String, (Any?) -> Unit>()

    internal fun registerResultCallback(onResult: (Any?) -> Unit): String {
        val id = java.util.UUID.randomUUID().toString()
        synchronized(pendingResultCallbacks) { pendingResultCallbacks[id] = onResult }
        return id
    }

    /**
     * Delivers [result] to the callback registered under [id], exactly once
     * (removal makes redundant deliveries no-ops).
     */
    internal fun deliverResult(id: String?, result: Any?) {
        if (id == null) return
        val callback = synchronized(pendingResultCallbacks) { pendingResultCallbacks.remove(id) }
        callback?.invoke(result)
    }

    // ── Dialog API ────────────────────────────────────────────────────────

    /**
     * Present a Flutter dialog in a transparent native container.
     *
     * Shows a [InlayFlutterDialogFragment] that hosts a Flutter engine
     * with a fullscreen transparent window. Flutter renders the dialog content.
     *
     * ```kotlin
     * InlayNavigator.presentDialog(activity, ConfirmDeleteDialog(itemId = "42"))
     * ```
     */
    fun presentDialog(activity: FragmentActivity, route: FlutterDialogRoute) {
        init(activity, prewarm = isPrewarmEnabled)
        val page = route.toPageSettings()
        val dialogFragment = createDialogFragment(activity, page)
        dialogFragment.show(activity.supportFragmentManager, page.routeId)
    }

    /**
     * Present a Flutter dialog that returns a typed result.
     *
     * [onResult] is invoked exactly once - with the decoded result the
     * dialog pops with, or `null` when it is dismissed without one
     * (barrier tap, back).
     *
     * ```kotlin
     * InlayNavigator.presentDialog(activity, ConfirmDeleteDialog(itemId = "42")) { confirmed -> ... }
     * ```
     */
    fun <R : Any> presentDialog(
        activity: FragmentActivity,
        route: FlutterDialogRouteWithResult<R>,
        onResult: (R?) -> Unit,
    ) {
        init(activity, prewarm = isPrewarmEnabled)
        val page = route.toPageSettings()
        val dialogFragment = createDialogFragment(activity, page) { raw ->
            onResult(route.decodeResult(raw))
        }
        dialogFragment.show(activity.supportFragmentManager, page.routeId)
    }

    /**
     * Create a [InlayFlutterDialogFragment] configured for the given page.
     */
    fun createDialogFragment(
        context: Context,
        route: FlutterDialogRoute,
    ): InlayFlutterDialogFragment {
        return createDialogFragment(context, route.toPageSettings())
    }

    /**
     * Create a [InlayFlutterDialogFragment] for a dialog that returns a
     * typed result.
     *
     * [onResult] is invoked exactly once - with the decoded result, or
     * `null` when the dialog is dismissed without one (barrier tap, back).
     */
    fun <R : Any> createDialogFragment(
        context: Context,
        route: FlutterDialogRouteWithResult<R>,
        onResult: (R?) -> Unit,
    ): InlayFlutterDialogFragment {
        return createDialogFragment(context, route.toPageSettings()) { raw ->
            onResult(route.decodeResult(raw))
        }
    }

    /**
     * Low-level factory operating on raw [PageSettings]; prefer the typed
     * route overloads. [onResult] receives the wire-format result the
     * dialog pops with, or `null` on dismissal without one.
     */
    @JvmOverloads
    fun createDialogFragment(
        context: Context,
        page: PageSettings,
        onResult: ((Any?) -> Unit)? = null,
    ): InlayFlutterDialogFragment {
        init(context, prewarm = isPrewarmEnabled)
        val fragment = InlayFlutterDialogFragment()
        fragment.arguments = Bundle().apply {
            writeRouteData(this, page)
            if (onResult != null) {
                putString(EXTRA_RESULT_ID, registerResultCallback(onResult))
            }
        }
        return fragment
    }

    /**
     * Create an [InlayFlutterFragment] with transparent background for use
     * inside a [InlayFlutterDialogFragment].
     */
    internal fun createDialogFlutterFragment(context: Context, page: PageSettings): InlayFlutterFragment {
        init(context, prewarm = isPrewarmEnabled)
        val initialRoute = encodePageSettings(page)
        val fragment = FlutterFragment.NewEngineInGroupFragmentBuilder(
            InlayFlutterFragment::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(dartEntrypoint)
            .initialRoute(initialRoute)
            .transparencyMode(TransparencyMode.transparent)
            .build<InlayFlutterFragment>()
        fragment.arguments = (fragment.arguments ?: Bundle()).apply {
            writeRouteData(this, page)
            putBoolean(InlayFlutterFragment.ARG_USE_BACK_DISPATCHER, true)
        }
        return fragment
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
     * InlayNavigator.setNativeRouteHandler(object : NativeRouteHandler() {
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
    internal fun dispatchNativeRoute(
        context: Context,
        route: PageSettings,
        completion: (Any?) -> Unit = {},
    ) {
        val handler = nativeRouteHandler
            ?: throw IllegalStateException(
                "No native route handler set. " +
                "Call InlayNavigator.setNativeRouteHandler() in your Application.onCreate()."
            )
        handler.handle(context, route, completion)
    }

    // ── Fragment factory ──────────────────────────────────────────────────

    /**
     * Create an [InlayFlutterFragment] configured to display the page
     * described by [route].
     *
     * The returned fragment can be added to any Activity via a
     * FragmentTransaction:
     * ```kotlin
     * val fragment = InlayNavigator.createFragment(context, SoundsNotificationsPage(contactId = "42"))
     * supportFragmentManager.beginTransaction()
     *     .replace(R.id.container, fragment)
     *     .commit()
     * ```
     *
     * Engine configuration (Pigeon APIs, storage) is set up automatically
     * when the fragment attaches — no manual wiring needed.
     */
    @JvmOverloads
    fun createFragment(
        context: Context,
        route: FlutterRoute,
        useBackDispatcher: Boolean = false,
    ): InlayFlutterFragment {
        return createFragment(context, route.toPageSettings(), useBackDispatcher)
    }

    /**
     * Create an [InlayFlutterFragment] for a Flutter page that returns a
     * typed result.
     *
     * [onResult] is invoked exactly once — with the decoded result the
     * Flutter page pops with, or `null` when the fragment is destroyed
     * without one. Like Activity result callbacks, it lives in process
     * memory and is not restored across process death.
     */
    fun <R : Any> createFragment(
        context: Context,
        route: FlutterRouteWithResult<R>,
        useBackDispatcher: Boolean = false,
        onResult: (R?) -> Unit,
    ): InlayFlutterFragment {
        return createFragment(context, route.toPageSettings(), useBackDispatcher) { raw ->
            onResult(route.decodeResult(raw))
        }
    }

    @JvmOverloads
    fun createFragment(
        context: Context,
        page: PageSettings,
        useBackDispatcher: Boolean = false,
        onResult: ((Any?) -> Unit)? = null,
    ): InlayFlutterFragment {
        init(context, prewarm = isPrewarmEnabled)
        val initialRoute = encodePageSettings(page)
        val fragment = FlutterFragment.NewEngineInGroupFragmentBuilder(
            InlayFlutterFragment::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(dartEntrypoint)
            .initialRoute(initialRoute)
            .build<InlayFlutterFragment>()
        val args = fragment.arguments ?: Bundle().also { fragment.arguments = it }
        writeRouteData(args, page)
        if (useBackDispatcher) {
            args.putBoolean(InlayFlutterFragment.ARG_USE_BACK_DISPATCHER, true)
        }
        if (onResult != null) {
            args.putString(EXTRA_RESULT_ID, registerResultCallback(onResult))
        }
        return fragment
    }

    // ── Intent factory ───────────────────────────────────────────────────

    internal fun createIntent(context: Context, page: PageSettings): Intent {
        init(context, prewarm = isPrewarmEnabled)
        val initialRoute = encodePageSettings(page)
        val intent = FlutterActivity.NewEngineInGroupIntentBuilder(
            InlayFlutterActivity::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(dartEntrypoint)
            .initialRoute(initialRoute)
            .build(context)
        putRouteDataExtra(intent, page)
        return intent
    }

    // ── Route data serialization (Intent extras / Fragment arguments) ─────

    internal const val EXTRA_RESULT_ID = "inlay_result_id"
    private const val EXTRA_ROUTE_ID = "inlay_route_id"
    private const val EXTRA_ROUTE_PATH = "inlay_route_path"
    private const val EXTRA_ROUTE_PARAMS = "inlay_route_params"
    private const val EXTRA_ROUTE_FINGERPRINT = "inlay_route_fingerprint"

    /**
     * Writes [page] into [bundle] in a process-death-safe encoding.
     *
     * Route data lives in framework-persisted state (Intent extras or
     * Fragment arguments), never in an in-memory map: a container restored
     * after process death must still recover its full typed route in
     * `configureFlutterEngine`, otherwise `getInitialRouteData()` returns
     * `null` and non-path parameters are lost. [PageSettings.params] is
     * pigeon-encoded so the typed positional list round-trips intact.
     */
    private fun writeRouteData(bundle: Bundle, page: PageSettings) {
        bundle.putString(EXTRA_ROUTE_ID, page.routeId)
        page.path?.let { bundle.putString(EXTRA_ROUTE_PATH, it) }
        page.schemaFingerprint?.let { bundle.putString(EXTRA_ROUTE_FINGERPRINT, it) }
        encodeRouteParams(page.params)?.let { bundle.putByteArray(EXTRA_ROUTE_PARAMS, it) }
    }

    /** Reads what [writeRouteData] stored, or `null` when [bundle] has no route. */
    internal fun readRouteData(bundle: Bundle?): PageSettings? {
        if (bundle == null) return null
        val routeId = bundle.getString(EXTRA_ROUTE_ID) ?: return null
        return PageSettings(
            routeId,
            decodeRouteParams(bundle.getByteArray(EXTRA_ROUTE_PARAMS)),
            bundle.getString(EXTRA_ROUTE_PATH),
            bundle.getString(EXTRA_ROUTE_FINGERPRINT),
        )
    }

    private fun putRouteDataExtra(intent: Intent, page: PageSettings) {
        intent.putExtras(Bundle().apply { writeRouteData(this, page) })
    }

    internal fun extractRouteDataFromIntent(intent: Intent): PageSettings? =
        readRouteData(intent.extras)

    /** Pigeon-encodes [params] (`StandardMessageCodec`); `null` stays `null`. */
    internal fun encodeRouteParams(params: Any?): ByteArray? {
        if (params == null) return null
        val buffer = StandardMessageCodec.INSTANCE.encodeMessage(params) ?: return null
        buffer.flip()
        val bytes = ByteArray(buffer.remaining())
        buffer.get(bytes)
        return bytes
    }

    /** Inverse of [encodeRouteParams]. */
    internal fun decodeRouteParams(bytes: ByteArray?): Any? {
        if (bytes == null) return null
        return StandardMessageCodec.INSTANCE.decodeMessage(ByteBuffer.wrap(bytes))
    }

    // ── Engine configuration (called by InlayFlutterActivity / Fragment) ─

    /**
     * Called by [InlayFlutterActivity.configureFlutterEngine] and
     * [InlayFlutterFragment.configureFlutterEngine].
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
        routeData: PageSettings? = null,
        resultId: String? = null,
    ) {
        onEngineCreated?.invoke(engine)
        val hostApi = object : InlayNavigatorHostApi {
            override fun push(page: PageSettings) {
                activity.startActivity(createIntent(activity, page))
            }
            override fun pushForResult(page: PageSettings, callback: (Result<Any?>) -> Unit) {
                val intent = createIntent(activity, page)
                intent.putExtra(EXTRA_RESULT_ID, registerResultCallback { callback(Result.success(it)) })
                activity.startActivity(intent)
            }
            override fun pop(result: Any?) {
                deliverResult(resultId, result)
                onPop?.invoke() ?: activity.finish()
            }
            override fun pushNativeRoute(route: PageSettings) {
                dispatchNativeRoute(activity, route)
            }
            override fun pushNativeRouteForResult(route: PageSettings, callback: (Result<Any?>) -> Unit) {
                try {
                    dispatchNativeRoute(activity, route) { callback(Result.success(it)) }
                } catch (e: IllegalStateException) {
                    callback(Result.failure(e))
                }
            }
            override fun setNativePopGestureEnabled(enabled: Boolean) {
                // iOS-only gesture toggle. No-op on Android.
            }
            override fun getInitialRouteData(): PageSettings? {
                return routeData
            }
            override fun presentDialog(page: PageSettings) {
                val fragmentActivity = activity as? FragmentActivity ?: return
                val dialogFragment = createDialogFragment(activity, page)
                fragmentActivity.supportFragmentManager.let { fm ->
                    dialogFragment.show(fm, page.routeId)
                }
            }
            override fun presentDialogForResult(page: PageSettings, callback: (Result<Any?>) -> Unit) {
                val fragmentActivity = activity as? FragmentActivity
                if (fragmentActivity == null) {
                    callback(Result.success(null))
                    return
                }
                val dialogFragment = createDialogFragment(activity, page) {
                    callback(Result.success(it))
                }
                dialogFragment.show(fragmentActivity.supportFragmentManager, page.routeId)
            }
        }
        InlayNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, hostApi)
        KeyValueStorageImpl.attachToEngine(engine)
    }

    /**
     * Called by [InlayFlutterActivity.cleanUpFlutterEngine] and
     * [InlayFlutterFragment.cleanUpFlutterEngine].
     */
    internal fun cleanUpEngine(engine: FlutterEngine) {
        InlayNavigatorHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        KeyValueStorageImpl.detachFromEngine(engine)
    }

    // ── Encoding ─────────────────────────────────────────────────────────

    internal fun encodePageSettings(page: PageSettings): String {
        page.path?.let { return it }

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
