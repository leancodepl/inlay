package org.thoughtcrime.securesms.flutter

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Method channel handler so Flutter can request opening add2app screens in a new
 * Android Activity (new engine). Enables spawning many engines from within Flutter.
 */
object Add2AppNavMethodChannel {

  private const val CHANNEL = "org.thoughtcrime.securesms/add2app_nav"
  private const val METHOD_OPEN_SET_WALLPAPER = "open_set_wallpaper"
  private const val METHOD_OPEN_SOUNDS_NOTIFICATIONS = "open_sounds_notifications"

  fun attach(flutterEngine: FlutterEngine, context: Context) {
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      try {
        val recipientId = call.arguments as? String
        when (call.method) {
          METHOD_OPEN_SET_WALLPAPER -> {
            context.startActivity(SetWallpaperFlutterActivity.createIntent(context, recipientId))
            result.success(null)
          }
          METHOD_OPEN_SOUNDS_NOTIFICATIONS -> {
            context.startActivity(SoundsNotificationsFlutterActivity.createIntent(context, recipientId))
            result.success(null)
          }
          else -> result.notImplemented()
        }
      } catch (e: Exception) {
        result.error("ADD2APP_NAV", e.message, null)
      }
    }
  }
}
