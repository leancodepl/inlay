import XCTest

extension XCUIApplication {

    /// Flutter exposes its semantics tree through accessibility labels on
    /// untyped elements - match by label instead of element type.
    func flutterElement(label: String) -> XCUIElement {
        descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    func flutterElement(labelContains fragment: String) -> XCUIElement {
        descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", fragment))
            .firstMatch
    }

    func tapButton(_ label: String, timeout: TimeInterval = 10,
                   file: StaticString = #filePath, line: UInt = #line) {
        let button = buttons[label]
        XCTAssertTrue(
            button.waitForExistence(timeout: timeout),
            "Button '\(label)' never appeared", file: file, line: line
        )
        button.tap()
    }

    /// Scrolls the current screen until the given button is hittable, then taps it.
    func scrollToAndTapButton(_ label: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        let button = buttons[label]
        var attempts = 0
        while (!button.exists || !button.isHittable) && attempts < 8 {
            scrollViews.firstMatch.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(
            button.exists && button.isHittable,
            "Button '\(label)' not reachable by scrolling", file: file, line: line
        )
        button.tap()
    }

    func openNativeSettings() {
        tapButton("Open Native Settings")
    }

    func goBackNative() {
        navigationBars.buttons.element(boundBy: 0).tap()
    }
}
