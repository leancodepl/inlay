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

  // The About screen runs in its own Activity, so we stash the awaiting
  // completion here and NativeAboutActivity delivers to it on finish. A
  // real app would use a result bus or a shared view model; the principle
  // is the same - deliver exactly once.
  private var pendingAboutFeedback: ((String) -> Unit)? = null

  override fun onNativeSettings(page: NativeSettingsPage, context: Context) {
    context.startAsInlayHost(Intent(context, NativeSettingsActivity::class.java))
  }

  override fun onNativeAbout(
    page: NativeAboutPage,
    context: Context,
    completion: (String) -> Unit,
  ) {
    pendingAboutFeedback = completion
    context.startAsInlayHost(
      Intent(context, NativeAboutActivity::class.java)
        .putExtra(EXTRA_VERSION, page.appVersion),
    )
  }

  /** Delivers About feedback to the awaiting Flutter caller, exactly once. */
  fun deliverAboutFeedback(feedback: String) {
    val completion = pendingAboutFeedback ?: return
    pendingAboutFeedback = null
    completion(feedback)
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
