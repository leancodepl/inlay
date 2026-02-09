package org.thoughtcrime.securesms.flutter

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.FlutterEngineGroupCache
import io.flutter.plugin.common.MethodChannel

/**
 * ADD2APP: Flutter Activity for Sounds & Notifications screen.
 * Always uses an engine from [FlutterEngineGroup] (via [FlutterEngineGroupCache]) for comparison
 * with [SetWallpaperFlutterActivity] (standalone engine) — e.g. memory, start time.
 * Each launch creates a new engine from the group (many engines supported); use
 * "Open again (new activity)" from Flutter to spawn more.
 */
class SoundsNotificationsFlutterActivity : FlutterActivity() {

  @NonNull
  override fun getDartEntrypointFunctionName(): String = "mainSoundsNotifications"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    Add2AppNavMethodChannel.attach(flutterEngine, this)
  }

  companion object {
    /** Engine group ID used in [FlutterEngineGroupCache]. */
    const val ENGINE_GROUP_ID = "signal_flutter_engine_group"

    @JvmStatic
    fun createIntent(context: Context, recipientId: String?): Intent {
      ensureEngineGroupRegistered(context.applicationContext)
      return FlutterActivity.NewEngineInGroupIntentBuilder(
        SoundsNotificationsFlutterActivity::class.java,
        ENGINE_GROUP_ID
      )
        .dartEntrypoint("mainSoundsNotifications")
        .initialRoute(recipientId ?: "")
        .build(context)
    }

    /** Registers the FlutterEngineGroup in the cache if not already present (lazy init). */
    @JvmStatic
    private fun ensureEngineGroupRegistered(applicationContext: Context) {
      if (!FlutterEngineGroupCache.getInstance().contains(ENGINE_GROUP_ID)) {
        val group = FlutterEngineGroup(applicationContext)
        FlutterEngineGroupCache.getInstance().put(ENGINE_GROUP_ID, group)
      }
    }
  }
}
