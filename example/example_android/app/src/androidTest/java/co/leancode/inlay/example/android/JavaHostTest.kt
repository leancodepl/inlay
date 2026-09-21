package co.leancode.inlay.example.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end tests for the Java output of inlay_gen, driven from
 * [JavaHostActivity]. The generated Java route classes must be accepted by
 * the Kotlin API (`FlutterRoute` / `FlutterRouteWithResult`), render the
 * same Flutter screens, and deliver typed results to a Java callback.
 */
@RunWith(AndroidJUnit4::class)
class JavaHostTest {

  @Test
  fun javaRouteOpensFlutterScreen() {
    val device = launchExampleApp()
    device.clickButton("Open Java host demo")

    device.clickButton("Open Flutter Greeting (Java)")
    assertNotNull(
      "The Java-generated GreetingPage never rendered.",
      device.waitForAny(30_000, By.text("Hello, Java."), By.desc("Hello, Java.")),
    )
  }

  @Test
  fun javaResultCallbackReceivesDialogResult() {
    val device = launchExampleApp()
    device.clickButton("Open Java host demo")

    device.clickButton("Open Confirm Dialog (Java)")
    val confirm = device.waitForAny(20_000, By.text("Confirm"), By.desc("Confirm"))
    assertNotNull("The Flutter confirm dialog never appeared.", confirm)
    confirm!!.click()

    assertNotNull(
      "The Java onResult callback never received the dialog's Boolean result.",
      device.waitForAny(20_000, By.text("Confirm dialog returned")),
    )
    assertNotNull(device.waitForAny(5_000, By.text("true")))
    device.clickButton("OK")
  }
}
