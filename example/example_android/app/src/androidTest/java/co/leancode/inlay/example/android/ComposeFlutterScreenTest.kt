package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Smoke test for the full-screen Compose embed (`InlayFlutterScreen`):
 * a Flutter page hosted as a Compose Navigation destination must render.
 */
@RunWith(AndroidJUnit4::class)
class ComposeFlutterScreenTest {

  @Test
  fun composeDestinationRendersFlutterCounter() {
    val device = launchExampleApp()

    device.clickButton("Open Compose + Flutter demo")
    device.clickButton("Open Flutter Counter")

    // First Flutter frame in an embedded fragment can be slow on a cold
    // emulator - accept any element the counter screen renders.
    assertNotNull(
      "The Flutter counter never rendered inside the Compose destination.",
      device.waitForAny(
        45_000,
        By.text("Reset"),
        By.desc("Reset"),
        By.textStartsWith("Count:"),
        By.descStartsWith("Count:"),
      ),
    )
  }
}
