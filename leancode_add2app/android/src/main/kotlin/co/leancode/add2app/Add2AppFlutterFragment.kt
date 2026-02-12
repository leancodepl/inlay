package co.leancode.add2app

import androidx.activity.ComponentActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngine

/**
 * Generic Flutter Fragment used by [Add2AppNavigator] for embedding Flutter pages
 * inside an existing Android Activity.
 *
 * This is the Fragment counterpart of [Add2AppFlutterActivity]. It can be used when
 * the developer wants to embed Flutter content within an Activity's view hierarchy
 * rather than launching a separate full-screen Flutter Activity.
 *
 * Use [Add2AppNavigator.createFragment] to create instances with the correct
 * engine group configuration, or build manually via
 * [FlutterFragment.NewEngineInGroupFragmentBuilder].
 *
 * ### Back-dispatcher mode
 *
 * When the [ARG_USE_BACK_DISPATCHER] argument is `true` (set automatically by
 * [Add2AppFlutterScreen]), Flutter's `pop()` calls
 * `onBackPressedDispatcher.onBackPressed()` instead of `activity.finish()`.
 * This integrates correctly with Compose Navigation, Fragment back stacks,
 * and any other `OnBackPressedCallback` consumers.
 */
class Add2AppFlutterFragment : FlutterFragment() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val useBackDispatcher =
            arguments?.getBoolean(ARG_USE_BACK_DISPATCHER, false) ?: false

        if (useBackDispatcher) {
            val componentActivity = requireActivity() as ComponentActivity
            Add2AppNavigator.configureEngine(flutterEngine, requireActivity()) {
                componentActivity.onBackPressedDispatcher.onBackPressed()
            }
        } else {
            Add2AppNavigator.configureEngine(flutterEngine, requireActivity())
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        Add2AppNavigator.cleanUpEngine(flutterEngine)
    }

    companion object {
        /**
         * Bundle key that switches the fragment to *back-dispatcher* mode.
         *
         * When `true`, Flutter's `pop()` invokes
         * `ComponentActivity.onBackPressedDispatcher.onBackPressed()` instead
         * of finishing the hosting Activity.
         */
        internal const val ARG_USE_BACK_DISPATCHER = "add2app_use_back_dispatcher"
    }
}
