package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end test for the `onResult` parameter of the Compose
 * `InlayFlutterDialogScreen` wrapper: the Flutter dialog's typed `Boolean`
 * result must reach the Compose host through the fragment result plumbing.
 */
@RunWith(AndroidJUnit4::class)
class ComposeDialogResultTest {

  @Test
  fun composeDialogDeliversTypedResult() {
    val device = launchExampleApp()

    device.clickButton("Open Compose + Flutter demo")
    device.clickButton("Open Confirm Dialog")

    val confirm = device.waitForAny(20_000, By.text("Confirm"), By.desc("Confirm"))
    assertNotNull("The Flutter confirm dialog never appeared in Compose.", confirm)
    confirm!!.click()

    assertNotNull(
      "The Compose host never received the dialog's Boolean result.",
      device.waitForAny(
        20_000,
        By.textContains("Confirm dialog returned: true"),
        By.descContains("Confirm dialog returned: true"),
      ),
    )
  }
}
