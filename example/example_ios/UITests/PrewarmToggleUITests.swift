import XCTest

/// Smoke test for `InlayNavigator.shared.setPrewarmEnabled`: with
/// prewarming off, navigation must still work (engines are created on
/// demand instead). Fresh launch per test resets the toggle.
final class PrewarmToggleUITests: XCTestCase {

    func testNavigationWorksWithPrewarmDisabled() {
        let app = XCUIApplication()
        app.launch()

        app.openNativeSettings()
        // The settings screen has a single switch - the prewarm toggle.
        let toggle = app.switches.firstMatch
        var attempts = 0
        while (!toggle.exists || !toggle.isHittable) && attempts < 8 {
            app.scrollViews.firstMatch.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(toggle.exists && toggle.isHittable, "Prewarm switch not reachable.")
        toggle.tap() // enabled by default -> disables prewarming
        app.goBackNative()

        app.tapButton("Open Flutter Greeting")
        XCTAssertTrue(
            app.flutterElement(label: "Hi iOS!").waitForExistence(timeout: 30),
            "Navigation broke with prewarming disabled."
        )
    }
}
