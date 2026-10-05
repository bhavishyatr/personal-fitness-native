import XCTest

final class PerformanceUITests: XCTestCase {
    @MainActor
    func testInsightsNavigationAndExclusions() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-snapshot", "--snapshot-insights"]
        app.launch()
        XCTAssertTrue(app.buttons["records-link"].waitForExistence(timeout: 20))
        app.buttons["records-link"].tap()
        let series = app.buttons["series-Badminton-Longest duration-Outdoor"]
        XCTAssertTrue(series.waitForExistence(timeout: 10))
        series.tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Top 10 performances"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-snapshot", "--snapshot-duplicates"]
        app.launch()
        let toggle = app.switches.matching(NSPredicate(format: "identifier BEGINSWITH %@", "include-")).firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 20))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertTrue(app.staticTexts["Excluded from analytics"].firstMatch.waitForExistence(timeout: 5))
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")
    }

    @MainActor
    func testCalendarAndRecapLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-snapshot", "--snapshot-calendar"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Activity calendar"].waitForExistence(timeout: 20))
        app.buttons["Previous month"].tap()
        app.buttons["Next month"].tap()
        app.terminate()
        app.launchArguments = ["--ui-snapshot", "--snapshot-recap"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Monthly recap"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Active days"].exists)
    }
}
