package co.leancode.add2app

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
 * The Dart entrypoint and initial route are configured via the Fragment arguments
 * (Bundle) set by the builder.
 */
class Add2AppFlutterFragment : FlutterFragment() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Add2AppNavigator.configureEngine(flutterEngine, requireActivity())
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        Add2AppNavigator.cleanUpEngine(flutterEngine)
    }
}
