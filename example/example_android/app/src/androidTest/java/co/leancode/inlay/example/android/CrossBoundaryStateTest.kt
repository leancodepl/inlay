package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiScrollable
import androidx.test.uiautomator.UiSelector
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end tests for cross-boundary state and typed results:
 * a native store write must be visible in a Flutter engine created
 * afterwards, and a Flutter screen's typed result must reach native.
 */
@RunWith(AndroidJUnit4::class)
class CrossBoundaryStateTest {

  @Test
  fun nativeStoreWriteIsVisibleInFlutterProfile() {
    val device = launchExampleApp()

    device.clickButton("Open Native Settings")
    device.clickButton("Set demo values")
    UiScrollable(UiSelector().scrollable(true))
      .scrollTextIntoView("Open Flutter Profile")
    device.clickButton("Open Flutter Profile")

    assertNotNull(
      "The Flutter profile never showed the natively written display name.",
      device.waitForAny(
        30_000,
        By.textContains("Display name: Native User"),
        By.descContains("Display name: Native User"),
      ),
    )
  }

  @Test
  fun counterReturnsTypedResultToNative() {
    val device = launchExampleApp()

    device.clickButton("Open Flutter Counter")

    // The counter store is shared app state - reset before incrementing so
    // the returned value is deterministic.
    val reset = device.waitForAny(30_000, By.text("Reset"), By.desc("Reset"))
    assertNotNull("The Flutter counter screen never appeared.", reset)
    reset!!.click()
    device.waitForAny(10_000, By.text("+"), By.desc("+"))!!.click()
    device.waitForAny(
      10_000,
      By.textContains("return count to caller"),
      By.descContains("return count to caller"),
    )!!.click()

    assertNotNull(
      "Native never received the counter's Int result.",
      device.waitForAny(20_000, By.text("Counter returned")),
    )
    assertNotNull(device.waitForAny(5_000, By.text("1")))
  }
}
