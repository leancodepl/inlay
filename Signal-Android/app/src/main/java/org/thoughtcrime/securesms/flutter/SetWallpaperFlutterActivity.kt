package org.thoughtcrime.securesms.flutter

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * ADD2APP: Flutter Activity for Set Wallpaper screen.
 * Uses a standalone Flutter engine (no FlutterEngineGroup) for comparison with
 * [SoundsNotificationsFlutterActivity] (engine group) — e.g. memory, start time.
 * Each launch creates a new engine; use "Open again (new activity)" from Flutter to spawn more.
 */
class SetWallpaperFlutterActivity : FlutterActivity() {

  @NonNull
  override fun getDartEntrypointFunctionName(): String = "mainSetWallpaper"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    Add2AppNavMethodChannel.attach(flutterEngine, this)
  }

  companion object {
    @JvmStatic
    fun createIntent(context: Context, recipientId: String?): Intent {
      return FlutterActivity.NewEngineIntentBuilder(SetWallpaperFlutterActivity::class.java)
        .initialRoute(recipientId ?: "")
        .build(context)
    }
  }
}
