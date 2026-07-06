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
}
