package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end test for passing a screen result back to native.
 *
 * The main activity opens the Flutter confirm dialog with an `onResult`
 * callback and shows the decoded `Boolean?` in an alert. This exercises
 * the full result path: Flutter `Navigator.pop(context, true)` ->
 * generated `encodeResult` -> `pop(result)` transport -> native
 * `onResult` -> generated `decodeResult`.
 */
@RunWith(AndroidJUnit4::class)
class ScreenResultTest {

  @Test
  fun confirmDialogReturnsTrueToNative() {
    val device = launchExampleApp()

    device.clickButton("Open Confirm Dialog")

    // Flutter renders the dialog; its Confirm action is in the a11y tree.
    val confirm = device.waitForAny(
      20_000,
      By.text("Confirm"),
      By.desc("Confirm"),
    )
    assertNotNull("The Flutter confirm dialog never appeared.", confirm)
    confirm!!.click()

    // Native shows the decoded result in an alert.
    assertNotNull(
      "Native never received the dialog's Boolean result.",
      device.waitForAny(20_000, By.text("Confirm dialog returned")),
    )
    assertNotNull(device.waitForAny(5_000, By.text("true")))
  }
}
