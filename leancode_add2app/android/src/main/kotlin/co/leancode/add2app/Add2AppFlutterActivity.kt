package co.leancode.add2app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Generic Flutter Activity used by [Add2AppNavigator] for every page.
 *
 * Developers never subclass this or reference it directly — they call
 * `Add2AppNavigator.push(context, pageSettings)` and this Activity is
 * created automatically.
 *
 * The Dart entrypoint and initial route are configured by the Intent
 * built in [Add2AppNavigator.createIntent].
 */
class Add2AppFlutterActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Add2AppNavigator.configureEngine(flutterEngine, this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        Add2AppNavigator.cleanUpEngine(flutterEngine)
    }
}
