package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.UiScrollable
import androidx.test.uiautomator.UiSelector
import org.junit.After
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Smoke test for `InlayNavigator.setPrewarmEnabled`: with prewarming off,
 * navigation must still work (engines are created on demand instead).
 */
@RunWith(AndroidJUnit4::class)
class PrewarmToggleTest {

  @After
  fun restorePrewarm() {
    // Prewarm state lives in app-process memory shared across tests.
    togglePrewarm(launchExampleApp(), expectChecked = true)
  }

  @Test
  fun navigationWorksWithPrewarmDisabled() {
    val device = launchExampleApp()
    togglePrewarm(device, expectChecked = false)

    device.clickButton("Open Flutter Greeting")
    assertNotNull(
      "Navigation broke with prewarming disabled.",
      device.waitForAny(30_000, By.text("Hi Android!"), By.desc("Hi Android!")),
    )
  }

  private fun togglePrewarm(device: UiDevice, expectChecked: Boolean) {
    device.clickButton("Open Native Settings")
    UiScrollable(UiSelector().scrollable(true))
      .scrollTextIntoView("Engine prewarming")
    val toggle = device.waitForAny(5_000, By.text("Engine prewarming"))
    assertNotNull("Prewarm switch not found.", toggle)
    if (toggle!!.isChecked != expectChecked) {
      toggle.click()
    }
    device.pressBack()
  }
}
