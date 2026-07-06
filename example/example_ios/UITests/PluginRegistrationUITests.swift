import XCTest

/// Regression test for third-party plugin registration on inlay engines.
///
/// The Flutter greeting screen renders host app info fetched via
/// `package_info_plus`, which resolves only when the host's
/// `setOnEngineCreated` callback ran `GeneratedPluginRegistrant` on the
/// engine backing that screen. Without it the call throws
/// `MissingPluginException` and the footer never appears.
final class PluginRegistrationUITests: XCTestCase {

    func testPushedFlutterScreenReceivesPluginData() {
        let app = XCUIApplication()
        app.launch()

        let greetingButton = app.buttons["Open Flutter Greeting"]
        XCTAssertTrue(greetingButton.waitForExistence(timeout: 10))
        greetingButton.tap()

        // Flutter exposes the footer Text through the accessibility tree.
        let hostInfo = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH 'Host app:'"))
            .firstMatch
        XCTAssertTrue(
            hostInfo.waitForExistence(timeout: 30),
            "The Flutter screen never showed package_info_plus data — "
                + "plugins are likely not registered on the screen's engine."
        )
    }
}
