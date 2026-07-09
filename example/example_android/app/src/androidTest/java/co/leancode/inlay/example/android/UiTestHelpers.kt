package co.leancode.inlay.example.android

import android.content.Intent
import android.os.SystemClock
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.BySelector
import androidx.test.uiautomator.StaleObjectException
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.UiObject2
import androidx.test.uiautomator.Until

internal const val EXAMPLE_PACKAGE = "co.leancode.inlay.example.android"

/** Launches the example app fresh on the home screen and waits for it. */
internal fun launchExampleApp(): UiDevice {
  val instrumentation = InstrumentationRegistry.getInstrumentation()
  val device = UiDevice.getInstance(instrumentation)
  device.pressHome()
  val context = instrumentation.targetContext
  val intent = context.packageManager.getLaunchIntentForPackage(EXAMPLE_PACKAGE)!!
    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
  context.startActivity(intent)
  device.wait(Until.hasObject(By.pkg(EXAMPLE_PACKAGE).depth(0)), 15_000)
  return device
}

/**
 * Waits until any of [selectors] matches and returns the first match.
 *
 * Flutter exposes its semantics tree as content descriptions while native
 * views use text, so assertions on Flutter-rendered content should pass
 * both a `text` and a `desc` selector.
 */
internal fun UiDevice.waitForAny(timeoutMs: Long, vararg selectors: BySelector): UiObject2? {
  val deadline = SystemClock.uptimeMillis() + timeoutMs
  while (SystemClock.uptimeMillis() < deadline) {
    for (selector in selectors) {
      findObject(selector)?.let { return it }
    }
    SystemClock.sleep(250)
  }
  return null
}

/**
 * Clicks a native button by its (exact) text.
 *
 * Clicks only once two consecutive finds return identical bounds - right
 * after a scroll the click coordinates would otherwise be computed from
 * pre-settle bounds and land on a neighboring view. Also re-finds and
 * retries on [StaleObjectException] (Compose recomposition can invalidate
 * a node between find and click).
 */
internal fun UiDevice.clickButton(text: String, timeoutMs: Long = 15_000): UiObject2 {
  val deadline = SystemClock.uptimeMillis() + timeoutMs
  var lastError: Throwable? = null
  var lastBounds: android.graphics.Rect? = null
  while (SystemClock.uptimeMillis() < deadline) {
    val button = findObject(By.text(text))
    if (button != null) {
      try {
        val bounds = button.visibleBounds
        if (bounds == lastBounds) {
          button.click()
          return button
        }
        lastBounds = bounds
      } catch (e: StaleObjectException) {
        lastError = e
        lastBounds = null
      }
    }
    SystemClock.sleep(250)
  }
  throw AssertionError("Button '$text' never appeared or stayed stable", lastError)
}
