package co.leancode.add2app.example.android

import android.app.Activity
import android.content.Context
import android.content.Intent
import co.leancode.add2app.navigator.PageSettings
import co.leancode.example_module.generated.NativeAboutPage
import co.leancode.example_module.generated.NativeRouteHandler
import co.leancode.example_module.generated.NativeSettingsPage

object ExampleNativeRouteHandler : NativeRouteHandler() {
  private const val EXTRA_VERSION = "extra_version"

  override fun onNativeSettings(page: NativeSettingsPage, context: Context) {
    context.startAsAdd2AppHost(Intent(context, NativeSettingsActivity::class.java))
  }

  override fun onNativeAbout(page: NativeAboutPage, context: Context) {
    context.startAsAdd2AppHost(
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

private fun Context.startAsAdd2AppHost(intent: Intent) {
  if (this !is Activity) {
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  }
  startActivity(intent)
}
