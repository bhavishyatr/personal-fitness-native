import XCTest

final class PerformanceUITests: XCTestCase {
    @MainActor
    func testInsightsNavigationAndExclusions() {
        continueAfterFailure = false
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
        let identifier = toggle.identifier
        let sameWorkout = app.switches.matching(identifier: identifier).firstMatch
        print("Exclusion control before tap: \(sameWorkout.debugDescription)")
        XCTAssertEqual(sameWorkout.value as? String, "1")
        sameWorkout.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        print("Exclusion control after tap: \(app.debugDescription)")
        XCTAssertTrue(app.navigationBars["Data quality"].exists)
        let excluded = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0"), object: sameWorkout)
        XCTAssertEqual(XCTWaiter.wait(for: [excluded], timeout: 5), .completed)
        sameWorkout.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: sameWorkout)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 5), .completed)
    }

    @MainActor
    func testCalendarAndRecapLaunch() {
        continueAfterFailure = false
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
