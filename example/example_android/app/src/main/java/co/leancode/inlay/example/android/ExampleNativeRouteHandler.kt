package co.leancode.inlay.example.android

import android.app.Activity
import android.content.Context
import android.content.Intent
import co.leancode.inlay.navigator.PageSettings
import co.leancode.example_module.generated.NativeAboutPage
import co.leancode.example_module.generated.NativeRouteHandler
import co.leancode.example_module.generated.NativeSettingsPage

object ExampleNativeRouteHandler : NativeRouteHandler() {
  private const val EXTRA_VERSION = "extra_version"

  override fun onNativeSettings(page: NativeSettingsPage, context: Context) {
    context.startAsInlayHost(Intent(context, NativeSettingsActivity::class.java))
  }

  override fun onNativeAbout(page: NativeAboutPage, context: Context) {
    context.startAsInlayHost(
      Intent(context, NativeAboutActivity::class.java)
        .putExtra(EXTRA_VERSION, page.appVersion),
    )
  }

  override fun onUnknownRoute(route: PageSettings, context: Context) {
    throw IllegalArgumentException("Unknown route from Flutter: ${route.routeId}")
  }

  fun readVersion(intent: Intent): String {
    return intent.getStringExtra(EXTRA_VERSION) ?: "unknown"
  }
}

private fun Context.startAsInlayHost(intent: Intent) {
  if (this !is Activity) {
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  }
  startActivity(intent)
}
