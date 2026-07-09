import XCTest

/// End-to-end tests for cross-boundary state and typed results:
/// a native store write must be visible in a Flutter engine created
/// afterwards, and a Flutter screen's typed result must reach native.
final class CrossBoundaryStateUITests: XCTestCase {

    func testNativeStoreWriteIsVisibleInFlutterProfile() {
        let app = XCUIApplication()
        app.launch()

        app.openNativeSettings()
        app.tapButton("Set demo values")
        app.scrollToAndTapButton("Open Flutter Profile")

        XCTAssertTrue(
            app.flutterElement(labelContains: "Display name: Native User")
                .waitForExistence(timeout: 30),
            "The Flutter profile never showed the natively written display name."
        )
    }

    func testCounterReturnsTypedResultToNative() {
        let app = XCUIApplication()
        app.launch()

        app.tapButton("Open Counter (await result)")

        let reset = app.flutterElement(label: "Reset")
        XCTAssertTrue(reset.waitForExistence(timeout: 30), "The Flutter counter never appeared.")
        reset.tap()
        app.flutterElement(label: "+").tap()
        app.flutterElement(labelContains: "return count to caller").tap()

        XCTAssertTrue(
            app.staticTexts["Counter returned"].waitForExistence(timeout: 20),
            "Native never received the counter's Int result."
        )
        XCTAssertTrue(app.staticTexts["1"].waitForExistence(timeout: 5))
    }
}
