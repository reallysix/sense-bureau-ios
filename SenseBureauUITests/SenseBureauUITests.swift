import XCTest

final class SenseBureauUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testPauseResumeAndRecalibrateControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appLanguage", "en"]
        app.launch()

        let screenTitle = app.staticTexts["screenTitle"]
        XCTAssertTrue(screenTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(screenTitle.label, "MAG FIELD")
        XCTAssertGreaterThanOrEqual(screenTitle.frame.width, 70)

        let pauseResumeButton = app.buttons["pauseResumeButton"]
        XCTAssertTrue(pauseResumeButton.waitForExistence(timeout: 5))

        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: pauseResumeButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)

        pauseResumeButton.tap()
        XCTAssertEqual(pauseResumeButton.label, "RESUME")

        pauseResumeButton.tap()
        XCTAssertEqual(pauseResumeButton.label, "PAUSE")

        let calibrateButton = app.buttons["calibrateButton"]
        calibrateButton.tap()
        XCTAssertFalse(pauseResumeButton.isEnabled)
    }

    @MainActor
    func testLanguageSwitchUpdatesAndPersists() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appLanguage", "en"]
        app.launch()

        app.buttons["settingsButton"].tap()

        let settingsTitle = app.staticTexts["settingsTitle"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(settingsTitle.label, "SETTINGS")

        app.buttons["language.zh-Hans"].tap()
        XCTAssertEqual(settingsTitle.label, "设置")

        app.buttons["closeSettingsButton"].tap()
        let screenTitle = app.staticTexts["screenTitle"]
        XCTAssertTrue(screenTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(screenTitle.label, "磁场探测")

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "磁场探测")
    }

    @MainActor
    func testThemeSwitchPersistsWithoutResettingMeasurement() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appLanguage", "en", "-appTheme", "techSignal"]
        app.launch()

        let pauseResumeButton = app.buttons["pauseResumeButton"]
        XCTAssertTrue(pauseResumeButton.waitForExistence(timeout: 5))
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: pauseResumeButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
        pauseResumeButton.tap()
        XCTAssertEqual(pauseResumeButton.label, "RESUME")

        app.buttons["settingsButton"].tap()
        let techTheme = app.buttons["theme.techSignal"]
        let cartoonTheme = app.buttons["theme.cartoonExplorer"]
        XCTAssertTrue(cartoonTheme.waitForExistence(timeout: 3))
        XCTAssertEqual(techTheme.value as? String, "Selected")
        captureScreen(named: "theme-settings-tech")

        cartoonTheme.tap()
        XCTAssertEqual(cartoonTheme.value as? String, "Selected")
        captureScreen(named: "theme-settings-cartoon")
        app.buttons["closeSettingsButton"].tap()

        XCTAssertEqual(pauseResumeButton.label, "RESUME")
        XCTAssertTrue(pauseResumeButton.isEnabled)
        captureScreen(named: "theme-main-cartoon-paused")

        app.terminate()
        app.launchArguments = ["-appLanguage", "en"]
        app.launch()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["theme.cartoonExplorer"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["theme.cartoonExplorer"].value as? String, "Selected")
    }

    private func captureScreen(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
