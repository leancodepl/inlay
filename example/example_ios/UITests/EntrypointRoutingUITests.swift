import XCTest

/// End-to-end tests for the configurable Dart entrypoint
/// (`InlayNavigator.shared.setDartEntrypoint`). Each routing integration -
/// auto_route and the imperative sealed-class switch - must render pushed
/// screens and deliver typed results just like the default go_router one.
///
/// Every test launches a fresh app process, so the entrypoint always
/// starts as the default `inlayMain` - no restore step needed.
final class EntrypointRoutingUITests: XCTestCase {

    func testAutoRouteEntrypointRendersFlutterScreens() {
        let app = XCUIApplication()
        app.launch()

        app.openNativeSettings()
        app.scrollToAndTapButton("Routing: auto_route")
        app.goBackNative()

        app.tapButton("Open Flutter Greeting")
        XCTAssertTrue(
            app.flutterElement(label: "Hi iOS!").waitForExistence(timeout: 30),
            "The auto_route entrypoint never rendered the greeting screen."
        )
    }

    func testAutoRouteEntrypointDeliversDialogResult() {
        let app = XCUIApplication()
        app.launch()

        app.openNativeSettings()
        app.scrollToAndTapButton("Routing: auto_route")
        app.goBackNative()

        // Exercises InlayDialogLauncher in a transparent auto_route route.
        app.tapButton("Open Confirm Dialog (await result)")
        let confirm = app.flutterElement(label: "Confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: 20))
        confirm.tap()

        XCTAssertTrue(
            app.staticTexts["Confirm dialog returned"].waitForExistence(timeout: 20),
            "Native never received the dialog's result from the auto_route entrypoint."
        )
        XCTAssertTrue(app.staticTexts["true"].waitForExistence(timeout: 5))
    }

    func testImperativeEntrypointRendersFlutterScreens() {
        let app = XCUIApplication()
        app.launch()

        app.openNativeSettings()
        app.scrollToAndTapButton("Routing: imperative")
        app.goBackNative()

        app.tapButton("Open Flutter Greeting")
        XCTAssertTrue(
            app.flutterElement(label: "Hi iOS!").waitForExistence(timeout: 30),
            "The imperative entrypoint never rendered the greeting screen."
        )
    }

    func testImperativeEntrypointDeliversDialogResult() {
        let app = XCUIApplication()
        app.launch()

        app.openNativeSettings()
        app.scrollToAndTapButton("Routing: imperative")
        app.goBackNative()

        // Exercises runInlayDialog + encodeResult end to end.
        app.tapButton("Open Confirm Dialog (await result)")
        let confirm = app.flutterElement(label: "Confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: 20))
        confirm.tap()

        XCTAssertTrue(
            app.staticTexts["Confirm dialog returned"].waitForExistence(timeout: 20),
            "Native never received the dialog's result from the imperative entrypoint."
        )
        XCTAssertTrue(app.staticTexts["true"].waitForExistence(timeout: 5))
    }
}
