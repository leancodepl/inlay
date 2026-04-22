package co.leancode.inlay

import androidx.activity.ComponentActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngine

/**
 * Generic Flutter Fragment used by [InlayNavigator] for embedding Flutter pages
 * inside an existing Android Activity.
 *
 * This is the Fragment counterpart of [InlayFlutterActivity]. It can be used when
 * the developer wants to embed Flutter content within an Activity's view hierarchy
 * rather than launching a separate full-screen Flutter Activity.
 *
 * Use [InlayNavigator.createFragment] to create instances with the correct
 * engine group configuration, or build manually via
 * [FlutterFragment.NewEngineInGroupFragmentBuilder].
 *
 * ### Back-dispatcher mode
 *
 * When the [ARG_USE_BACK_DISPATCHER] argument is `true` (set automatically by
 * [InlayNavigator.createFragment] when `useBackDispatcher = true`, e.g. from
 * the `InlayFlutterScreen` composable in the `inlay_compose` plugin),
 * Flutter's `pop()` calls `onBackPressedDispatcher.onBackPressed()` instead
 * of `activity.finish()`. This integrates correctly with Compose Navigation,
 * Fragment back stacks, and any other `OnBackPressedCallback` consumers.
 */
class InlayFlutterFragment : FlutterFragment() {

    /**
     * Optional override for the pop behaviour. When set, this is called
     * instead of the default `activity.finish()` or back-dispatcher logic.
     *
     * Used by [InlayFlutterDialogFragment] to dismiss the dialog directly,
     * bypassing `onBackPressedDispatcher` (which would re-enter the Flutter
     * engine's own back-pressed callback and cause the activity to finish).
     */
    internal var onPopOverride: (() -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val customOnPop = onPopOverride
        val useBackDispatcher =
            arguments?.getBoolean(ARG_USE_BACK_DISPATCHER, false) ?: false
        val fragmentId = arguments?.getString(EXTRA_FRAGMENT_ROUTE_ID)
        val routeData = InlayNavigator.consumePendingRouteData(fragmentId)

        if (customOnPop != null) {
            InlayNavigator.configureEngine(flutterEngine, requireActivity(), onPop = customOnPop, routeData = routeData)
        } else if (useBackDispatcher) {
            val componentActivity = requireActivity() as ComponentActivity
            InlayNavigator.configureEngine(flutterEngine, requireActivity(), onPop = {
                componentActivity.onBackPressedDispatcher.onBackPressed()
            }, routeData = routeData)
        } else {
            InlayNavigator.configureEngine(flutterEngine, requireActivity(), routeData = routeData)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        InlayNavigator.cleanUpEngine(flutterEngine)
    }

    companion object {
        /**
         * Bundle key that switches the fragment to *back-dispatcher* mode.
         *
         * When `true`, Flutter's `pop()` invokes
         * `ComponentActivity.onBackPressedDispatcher.onBackPressed()` instead
         * of finishing the hosting Activity.
         */
        internal const val ARG_USE_BACK_DISPATCHER = "inlay_use_back_dispatcher"
        private const val EXTRA_FRAGMENT_ROUTE_ID = "inlay_fragment_route_id"
    }
}
