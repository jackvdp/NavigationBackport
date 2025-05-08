import XCTest

/// XCUITests that cover every permutation exercised in the QueueAnalyser unit‑tests.
/// Scenario buttons live in a **vertical** list (accessibilityIdentifier "scenarioList").
final class NavigationBackportUITests: XCTestCase {
    private var app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: ‑ Helper
    /// Tap the scenario‑chooser button with the given id.  Vertically scrolls until visible.
    @discardableResult
    private func openScenario(_ id: String, file: StaticString = #file, line: UInt = #line) -> XCUIElement {
        let buttonId = "scenario_" + id
        let button = app.buttons[buttonId]
        button.tap();
        return button
    }

    private func label(_ id: String) -> XCUIElement {
        let el = app.staticTexts[id]
        XCTAssertTrue(el.waitForExistence(timeout: 3), "Label \(id) missing")
        return el
    }

    // MARK: ‑ Tests (unchanged assertions)

    func testSimplePushPopRoot() {
        openScenario("123")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 3")
        app.buttons["previousButton"].tap()
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 2")
        app.buttons["goRootButton"].tap()
        XCTAssertTrue(app.staticTexts["rootLabel"].exists)
    }

    func testSetPushScenario() {
        openScenario("24")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 2")
        openScenario("2345")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 4")
    }

    func testSetPopScenario() {
        openScenario("1245")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 4")
        openScenario("123")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 3")
    }

    func testDuplicatesMiddleScenario() {
        openScenario("1dup2224")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 5")
        app.buttons["previousButton"].tap()
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 4")
    }

    func testDuplicatesEndScenario() {
        openScenario("12dup")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 5")
        app.buttons["goRootButton"].tap()
        XCTAssertTrue(app.staticTexts["rootLabel"].exists)
        openScenario("12dup")
        XCTAssertEqual(label("pathCountLabel").label, "PathCount: 5")
    }

    func testBlueCounterResetsAfterPop() {
        openScenario("123")
        // navigate to blue page (pop one from yellow)
        app.buttons["previousButton"].tap()
        let counter = label("blueCounterLabel")
        counter.tap()
        XCTAssertEqual(counter.label, "Blue View: 1")
        app.buttons["goRootButton"].tap()
        openScenario("123")
        app.buttons["previousButton"].tap()
        XCTAssertEqual(label("blueCounterLabel").label, "Blue View: 0")
    }
}
