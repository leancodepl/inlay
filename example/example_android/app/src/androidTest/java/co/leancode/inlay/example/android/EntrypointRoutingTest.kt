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
 * End-to-end tests for the configurable Dart entrypoint
 * (`InlayNavigator.setDartEntrypoint`). Each routing integration -
 * auto_route and the imperative sealed-class switch - must render pushed
 * screens and deliver typed results just like the default go_router one.
 */
@RunWith(AndroidJUnit4::class)
class EntrypointRoutingTest {

  @After
  fun restoreGoRouter() {
    // The entrypoint lives in app-process memory, which instrumentation
    // tests share - always restore the default for other test classes.
    switchRouting(launchExampleApp(), "Routing: go_router")
  }

  @Test
  fun autoRouteEntrypointRendersFlutterScreens() {
    val device = launchExampleApp()
    switchRouting(device, "Routing: auto_route")

    device.clickButton("Open Flutter Greeting")
    assertNotNull(
      "The auto_route entrypoint never rendered the greeting screen.",
      device.waitForAny(30_000, By.text("Hi Android!"), By.desc("Hi Android!")),
    )
  }

  @Test
  fun autoRouteEntrypointDeliversDialogResult() {
    val device = launchExampleApp()
    switchRouting(device, "Routing: auto_route")

    // Exercises InlayDialogLauncher in a transparent auto_route route.
    device.clickButton("Open Confirm Dialog")
    val confirm = device.waitForAny(20_000, By.text("Confirm"), By.desc("Confirm"))
    assertNotNull("The auto_route confirm dialog never appeared.", confirm)
    confirm!!.click()

    assertNotNull(
      "Native never received the dialog's result from the auto_route entrypoint.",
      device.waitForAny(20_000, By.text("Confirm dialog returned")),
    )
    assertNotNull(device.waitForAny(5_000, By.text("true")))
    // Dismiss the result alert so the screen is clean for the next test.
    device.clickButton("OK")
  }

  @Test
  fun imperativeEntrypointRendersFlutterScreens() {
    val device = launchExampleApp()
    switchRouting(device, "Routing: imperative")

    device.clickButton("Open Flutter Greeting")
    assertNotNull(
      "The imperative entrypoint never rendered the greeting screen.",
      device.waitForAny(30_000, By.text("Hi Android!"), By.desc("Hi Android!")),
    )
  }

  @Test
  fun imperativeEntrypointDeliversDialogResult() {
    val device = launchExampleApp()
    switchRouting(device, "Routing: imperative")

    // Exercises runInlayDialog + encodeResult end to end.
    device.clickButton("Open Confirm Dialog")
    val confirm = device.waitForAny(20_000, By.text("Confirm"), By.desc("Confirm"))
    assertNotNull("The imperative confirm dialog never appeared.", confirm)
    confirm!!.click()

    assertNotNull(
      "Native never received the dialog's result from the imperative entrypoint.",
      device.waitForAny(20_000, By.text("Confirm dialog returned")),
    )
    assertNotNull(device.waitForAny(5_000, By.text("true")))
    // Dismiss the result alert so the screen is clean for the next test.
    device.clickButton("OK")
  }

  private fun switchRouting(device: UiDevice, label: String) {
    device.clickButton("Open Native Settings")
    UiScrollable(UiSelector().scrollable(true)).scrollTextIntoView(label)
    device.clickButton(label)
    device.pressBack()
  }
}
