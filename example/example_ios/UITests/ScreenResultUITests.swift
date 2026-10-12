import XCTest

/// End-to-end test for passing a screen result back to native.
///
/// The UIKit home screen opens the Flutter confirm dialog with an
/// `onResult` callback and shows the decoded `Bool?` in an alert. This
/// exercises the full result path: Flutter `Navigator.pop(context, true)`
/// -> generated `encodeResult` -> `pop(result)` transport -> native
/// `onResult` -> generated `decodeResult`.
final class ScreenResultUITests: XCTestCase {

    func testConfirmDialogReturnsTrueToNative() {
        let app = XCUIApplication()
        app.launch()

        let confirmButton = app.buttons["Open Confirm Dialog (await result)"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10))
        confirmButton.tap()

        // Flutter renders the dialog; its Confirm action is in the a11y tree.
        let confirm = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == 'Confirm'"))
            .firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 20))
        confirm.tap()

        // Native shows the decoded result in an alert titled "Confirm dialog returned".
        let resultAlert = app.staticTexts["Confirm dialog returned"]
        XCTAssertTrue(
            resultAlert.waitForExistence(timeout: 20),
            "Native never received the dialog's Bool result."
        )
        XCTAssertTrue(app.staticTexts["true"].waitForExistence(timeout: 5))
    }

    /// Regression test: a Flutter screen with a typed result that pops
    /// without a value (here: the back button of the Flutter app bar) must
    /// deliver `nil` to native. The null arrives from Pigeon as `NSNull`;
    /// before the fix it reached the generated `decodeResult`, whose forced
    /// cast (`raw as! Int64`) crashed the app.
    func testCounterPopWithoutResultDeliversNil() {
        let app = XCUIApplication()
        app.launch()

        app.tapButton("Open Counter (await result)")

        let back = app.flutterElement(label: "Back")
        XCTAssertTrue(
            back.waitForExistence(timeout: 20),
            "The Flutter counter screen never appeared."
        )
        back.tap()

        XCTAssertTrue(
            app.staticTexts["Counter returned"].waitForExistence(timeout: 20),
            "Native never received the result. The app probably crashed."
        )
        XCTAssertTrue(app.staticTexts["dismissed"].waitForExistence(timeout: 5))
    }
}
