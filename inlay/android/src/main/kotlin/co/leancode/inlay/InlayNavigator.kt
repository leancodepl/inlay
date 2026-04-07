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

    /** The single Dart entrypoint used by all inlay pages. */
    private const val DART_ENTRYPOINT = "inlayMain"

    private lateinit var appContext: Context

    /** The single native route handler set by the app. */
    private var nativeRouteHandler: NativeRouteHandler? = null
    /** Whether [init] should prewarm a hidden engine. */
    private var isPrewarmEnabled: Boolean = true
    /** Hidden warm-up engine kept alive for app lifetime. */
    private var prewarmedEngine: FlutterEngine? = null
    /** Route data for fragments, keyed by fragment ID (consumed once on configureEngine). */
    private val pendingRouteData = mutableMapOf<String, PageSettings>()

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
        val entrypoint = DartExecutor.DartEntrypoint(bundlePath, DART_ENTRYPOINT)
        val engine = engineGroup.createAndRunEngine(appContext, entrypoint, PREWARM_ROUTE_ID)

        InlayNavigatorHostApi.setUp(
            engine.dartExecutor.binaryMessenger,
            object : InlayNavigatorHostApi {
                override fun push(page: PageSettings) {}
                override fun pop() {}
                override fun pushNativeRoute(route: PageSettings) {}
                override fun setNativePopGestureEnabled(enabled: Boolean) {}
                override fun getInitialRouteData(): PageSettings? = null
                override fun presentDialog(page: PageSettings) {}
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
     * Create a [InlayFlutterDialogFragment] configured for the given page.
     */
    fun createDialogFragment(context: Context, route: FlutterDialogRoute): InlayFlutterDialogFragment {
        return createDialogFragment(context, route.toPageSettings())
    }

    internal fun createDialogFragment(context: Context, page: PageSettings): InlayFlutterDialogFragment {
        init(context, prewarm = isPrewarmEnabled)
        val fragmentId = java.util.UUID.randomUUID().toString()
        pendingRouteData[fragmentId] = page
        val fragment = InlayFlutterDialogFragment()
        fragment.arguments = Bundle().apply {
            putString(InlayFlutterDialogFragment.EXTRA_DIALOG_ROUTE_ID, fragmentId)
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
        val fragmentId = java.util.UUID.randomUUID().toString()
        pendingRouteData[fragmentId] = page
        val fragment = FlutterFragment.NewEngineInGroupFragmentBuilder(
            InlayFlutterFragment::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(DART_ENTRYPOINT)
            .initialRoute(initialRoute)
            .transparencyMode(TransparencyMode.transparent)
            .build<InlayFlutterFragment>()
        fragment.arguments = (fragment.arguments ?: Bundle()).apply {
            putString(EXTRA_FRAGMENT_ROUTE_ID, fragmentId)
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
    internal fun dispatchNativeRoute(context: Context, route: PageSettings) {
        val handler = nativeRouteHandler
            ?: throw IllegalStateException(
                "No native route handler set. " +
                "Call InlayNavigator.setNativeRouteHandler() in your Application.onCreate()."
            )
        handler.handle(context, route)
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
    fun createFragment(context: Context, route: FlutterRoute): InlayFlutterFragment {
        return createFragment(context, route.toPageSettings())
    }

    internal fun createFragment(context: Context, page: PageSettings): InlayFlutterFragment {
        init(context, prewarm = isPrewarmEnabled)
        val initialRoute = encodePageSettings(page)
        val fragmentId = java.util.UUID.randomUUID().toString()
        pendingRouteData[fragmentId] = page
        val fragment = FlutterFragment.NewEngineInGroupFragmentBuilder(
            InlayFlutterFragment::class.java,
            ENGINE_GROUP_ID
        )
            .dartEntrypoint(DART_ENTRYPOINT)
            .initialRoute(initialRoute)
            .build<InlayFlutterFragment>()
        fragment.arguments?.putString(EXTRA_FRAGMENT_ROUTE_ID, fragmentId)
            ?: run {
                val args = android.os.Bundle()
                args.putString(EXTRA_FRAGMENT_ROUTE_ID, fragmentId)
                fragment.arguments = args
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
            .dartEntrypoint(DART_ENTRYPOINT)
            .initialRoute(initialRoute)
            .build(context)
        putRouteDataExtra(intent, page)
        return intent
    }

    // ── Route data serialization (Intent extras) ──────────────────────────

    private const val EXTRA_FRAGMENT_ROUTE_ID = "inlay_fragment_route_id"
    private const val EXTRA_ROUTE_ID = "inlay_route_id"
    private const val EXTRA_ROUTE_PATH = "inlay_route_path"
    private const val EXTRA_ROUTE_PARAMS = "inlay_route_params"

    private fun putRouteDataExtra(intent: Intent, page: PageSettings) {
        intent.putExtra(EXTRA_ROUTE_ID, page.routeId)
        page.path?.let { intent.putExtra(EXTRA_ROUTE_PATH, it) }
        page.params?.let { params ->
            val buffer = StandardMessageCodec.INSTANCE.encodeMessage(params)
            if (buffer != null) {
                intent.putExtra(EXTRA_ROUTE_PARAMS, bufferToByteArray(buffer))
            }
        }
    }

    internal fun extractRouteDataFromIntent(intent: Intent): PageSettings? {
        val routeId = intent.getStringExtra(EXTRA_ROUTE_ID) ?: return null
        val path = intent.getStringExtra(EXTRA_ROUTE_PATH)
        val paramsBytes = intent.getByteArrayExtra(EXTRA_ROUTE_PARAMS)
        val params = paramsBytes?.let {
            StandardMessageCodec.INSTANCE.decodeMessage(ByteBuffer.wrap(it))
        }
        return PageSettings(routeId, params, path)
    }

    internal fun consumePendingRouteData(fragmentId: String?): PageSettings? {
        if (fragmentId == null) return null
        return pendingRouteData.remove(fragmentId)
    }

    private fun bufferToByteArray(buffer: ByteBuffer): ByteArray {
        buffer.flip()
        val bytes = ByteArray(buffer.remaining())
        buffer.get(bytes)
        return bytes
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
    ) {
        val hostApi = object : InlayNavigatorHostApi {
            override fun push(page: PageSettings) {
                activity.startActivity(createIntent(activity, page))
            }
            override fun pop() {
                onPop?.invoke() ?: activity.finish()
            }
            override fun pushNativeRoute(route: PageSettings) {
                dispatchNativeRoute(activity, route)
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
