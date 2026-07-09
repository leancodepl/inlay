package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Regression test for third-party plugin registration on inlay engines.
 *
 * The Flutter greeting screen renders host app info fetched via
 * `package_info_plus`, which resolves only when plugins are registered on
 * the engine backing that screen (automatic on Android). Without it the
 * call throws `MissingPluginException` and the footer never appears.
 */
@RunWith(AndroidJUnit4::class)
class PluginRegistrationTest {

  @Test
  fun pushedFlutterScreenReceivesPluginData() {
    val device = launchExampleApp()

    device.clickButton("Open Flutter Greeting")

    val hostInfo = device.waitForAny(
      30_000,
      By.textStartsWith("Host app:"),
      By.descStartsWith("Host app:"),
    )
    assertNotNull(
      "The Flutter screen never showed package_info_plus data — " +
        "plugins are likely not registered on the screen's engine.",
      hostInfo,
    )
  }
}
