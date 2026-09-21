package co.leancode.inlay

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Generic Flutter Activity used by [InlayNavigator] for every page.
 *
 * Developers never subclass this or reference it directly — they call
 * `InlayNavigator.push(context, pageSettings)` and this Activity is
 * created automatically.
 *
 * The Dart entrypoint and initial route are configured by the Intent
 * built in [InlayNavigator.createIntent].
 */
class InlayFlutterActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // FlutterActivity resolves the cached engine group during onCreate.
        // After process death the in-memory cache is empty unless the app
        // initialized inlay in Application.onCreate, so re-register the group
        // first to avoid an IllegalStateException.
        InlayNavigator.ensureInitialized(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val routeData = InlayNavigator.extractRouteDataFromIntent(intent)
        InlayNavigator.configureEngine(
            flutterEngine,
            this,
            routeData = routeData,
            resultId = intent.getStringExtra(InlayNavigator.EXTRA_RESULT_ID),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        InlayNavigator.cleanUpEngine(flutterEngine)
    }

    override fun onDestroy() {
        // Finished without an explicit result (system back, task swipe) -
        // the caller still gets its callback, with null. deliverResult is
        // exactly-once, so this is a no-op after pop(result).
        if (isFinishing) {
            InlayNavigator.deliverResult(
                intent.getStringExtra(InlayNavigator.EXTRA_RESULT_ID),
                null,
            )
        }
        super.onDestroy()
    }
}
