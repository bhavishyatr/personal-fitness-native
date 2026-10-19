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
    func testWorkoutSensorsAndManualSets() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-snapshot", "--snapshot-sensors"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Workout details"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Recorded range"].firstMatch.waitForExistence(timeout: 10))
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Cycling cadence"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--ui-snapshot", "--snapshot-sets"]
        app.launch()
        XCTAssertTrue(app.buttons["add-strength-set"].waitForExistence(timeout: 20))
        app.buttons["add-strength-set"].tap()
        let name = app.textFields["exercise-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Squat")
        app.buttons["save-strength-set"].tap()
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: "1. Squat").firstMatch.waitForExistence(timeout: 5))
        app.buttons.containing(.staticText, identifier: "1. Squat").firstMatch.tap()
        XCTAssertTrue(app.textFields["exercise-name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["exercise-name"].value as? String, "Squat")
        app.buttons["Cancel"].tap()
        let row = app.buttons.containing(.staticText, identifier: "1. Squat").firstMatch
        row.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["No sets entered yet."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testYearlyRecordsAndBestComparison() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-snapshot", "--snapshot-records"]
        app.launch()
        let picker = app.buttons["record-year-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 20))
        picker.tap()
        let year = String(Calendar.current.component(.year, from: Date()))
        app.buttons["record-year-\(year)"].tap()
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", year), object: picker)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed, app.debugDescription)
        let series = app.buttons["series-Badminton-Longest duration-Outdoor"]
        XCTAssertTrue(series.waitForExistence(timeout: 5))
        series.tap()
        XCTAssertTrue(app.staticTexts["Year: \(year)"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--ui-snapshot", "--snapshot-history"]
        app.launch()
        let session = app.buttons.containing(.staticText, identifier: "Running").firstMatch
        XCTAssertTrue(session.waitForExistence(timeout: 20))
        session.tap()
        app.buttons["compare-best-link"].tap()
        XCTAssertTrue(app.navigationBars["Compare with best"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Personal best"].firstMatch.exists)
    }

    @MainActor
    func testCalendarAndRecapLaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-snapshot", "--snapshot-calendar"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Activity calendar"].waitForExistence(timeout: 20))
        let currentMonth = Date().formatted(.dateTime.month(.wide).year())
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!.formatted(.dateTime.month(.wide).year())
        XCTAssertTrue(app.staticTexts[currentMonth].exists)
        app.buttons["Previous month"].tap()
        XCTAssertTrue(app.staticTexts[previousMonth].waitForExistence(timeout: 5))
        app.buttons["Next month"].tap()
        XCTAssertTrue(app.staticTexts[currentMonth].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--ui-snapshot", "--snapshot-recap"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Monthly recap"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Active days"].exists)
    }
}
