package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiScrollable
import androidx.test.uiautomator.UiSelector
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end test for cross-engine appearance propagation.
 *
 * Setting `InlayAppearance.localeLanguageTag` from native must reach the
 * Flutter engine created afterwards: the greeting screen renders
 * `Localizations.localeOf(context)`, so an engine started after the
 * override shows `Locale: pl`.
 */
@RunWith(AndroidJUnit4::class)
class AppearanceTest {

  @Test
  fun localeOverridePropagatesToFlutterEngines() {
    val device = launchExampleApp()

    device.clickButton("Open Native Settings")
    UiScrollable(UiSelector().scrollable(true))
      .scrollTextIntoView("Flutter language: polski")
    device.clickButton("Flutter language: polski")
    device.pressBack()

    device.clickButton("Open Flutter Greeting")
    val locale = device.waitForAny(
      30_000,
      By.textStartsWith("Locale: pl"),
      By.descStartsWith("Locale: pl"),
    )
    assertNotNull(
      "The Flutter screen never reflected the native locale override.",
      locale,
    )

    // Restore the system locale so other tests in this process are
    // unaffected (InlayAppearance state lives in app-process memory).
    device.pressBack()
    device.clickButton("Open Native Settings")
    UiScrollable(UiSelector().scrollable(true))
      .scrollTextIntoView("Flutter language: system")
    device.clickButton("Flutter language: system")
  }
}
