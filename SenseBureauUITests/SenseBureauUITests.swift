import XCTest

final class SenseBureauUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testPauseResumeAndRecalibrateControls() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "en")
        app.launch()
        app.buttons["nav.field"].tap()

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
        app.launchArguments = standardArguments(language: "en")
        app.launch()
        app.buttons["nav.field"].tap()

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
        app.launchArguments = standardArguments()
        app.launch()
        app.buttons["nav.field"].tap()
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "磁场探测")
    }

    @MainActor
    func testThemeSwitchPersistsWithoutResettingMeasurement() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "en", theme: "techSignal")
        app.launch()
        app.buttons["nav.field"].tap()

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
        app.launchArguments = standardArguments(language: "en")
        app.launch()
        app.buttons["nav.field"].tap()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["theme.cartoonExplorer"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["theme.cartoonExplorer"].value as? String, "Selected")
    }

    @MainActor
    func testNavigationPreservesPausedMeasurementSession() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "en", theme: "techSignal")
        app.launch()

        let homeTitle = app.staticTexts["homeTitle"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(homeTitle.label, "SENSE LAB")
        XCTAssertFalse(app.buttons["tool.vibration"].isEnabled)
        captureScreen(named: "stage2-home-tech-en")

        app.buttons["tool.magneticField"].tap()
        let pauseResumeButton = app.buttons["pauseResumeButton"]
        XCTAssertTrue(pauseResumeButton.waitForExistence(timeout: 5))
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: pauseResumeButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
        pauseResumeButton.tap()
        XCTAssertEqual(pauseResumeButton.label, "RESUME")
        XCTAssertTrue(app.descendants(matching: .any)["axis.x"].exists)

        let saveButton = app.buttons["saveRecordButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()
        XCTAssertTrue(saveButton.label.contains("SAVED"))
        captureScreen(named: "stage2-field-tech-en-paused")
        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["axis.z"].exists)
        captureScreen(named: "stage3-field-axes-tech-en")

        app.buttons["nav.lab"].tap()
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 3))
        app.buttons["nav.field"].tap()
        XCTAssertTrue(pauseResumeButton.waitForExistence(timeout: 3))
        XCTAssertEqual(pauseResumeButton.label, "RESUME")
        XCTAssertTrue(pauseResumeButton.isEnabled)

        app.buttons["nav.settings"].tap()
        XCTAssertTrue(app.staticTexts["settingsTitle"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["closeSettingsButton"].exists)
        captureScreen(named: "stage2-settings-tech-en")
    }

    @MainActor
    func testFirstRunGuideCompletesAndPersists() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-appLanguage", "en",
            "-appTheme", "techSignal",
            "-appSoundEnabled", "NO",
            "-hasSeenMagneticGuide", "NO",
        ]
        app.launch()
        app.buttons["nav.field"].tap()

        let guideTitle = app.staticTexts["guide.title"]
        XCTAssertTrue(guideTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(guideTitle.label, "BEFORE YOU MEASURE")
        captureScreen(named: "stage3-guide-tech-en")

        app.buttons["guide.begin"].tap()
        XCTAssertTrue(app.buttons["pauseResumeButton"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-appLanguage", "en", "-appSoundEnabled", "NO"]
        app.launch()
        app.buttons["nav.field"].tap()

        XCTAssertFalse(guideTitle.exists)
        XCTAssertTrue(app.staticTexts["screenTitle"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testMeasurementSettingsControlRealPreferences() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "en", theme: "cartoonExplorer")
        app.launch()
        app.buttons["nav.settings"].tap()

        let soundSwitch = app.switches["settings.sound"]
        if !soundSwitch.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(soundSwitch.waitForExistence(timeout: 3))
        XCTAssertEqual(soundSwitch.value as? String, "0")
        soundSwitch.tap()
        XCTAssertEqual(soundSwitch.value as? String, "1")

        let thresholdSlider = app.sliders["settings.threshold"]
        XCTAssertTrue(thresholdSlider.waitForExistence(timeout: 3))
        thresholdSlider.adjust(toNormalizedSliderPosition: 0.5)
        XCTAssertEqual(app.staticTexts["thresholdValue"].label, "55 μT")
        captureScreen(named: "stage3-settings-cartoon-en")
    }

    @MainActor
    func testChineseCartoonGuideLayout() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-appLanguage", "zh-Hans",
            "-appTheme", "cartoonExplorer",
            "-appSoundEnabled", "NO",
            "-hasSeenMagneticGuide", "NO",
        ]
        app.launch()
        app.buttons["nav.field"].tap()

        let guideTitle = app.staticTexts["guide.title"]
        XCTAssertTrue(guideTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(guideTitle.label, "测量前须知")
        captureScreen(named: "stage3-guide-cartoon-zh-Hans")
        app.buttons["guide.skip"].tap()
        XCTAssertTrue(app.buttons["pauseResumeButton"].waitForExistence(timeout: 5))
    }

    private func standardArguments(language: String? = nil, theme: String? = nil) -> [String] {
        var arguments = [
            "-hasSeenMagneticGuide", "YES",
            "-appSoundEnabled", "NO",
        ]
        if let language {
            arguments += ["-appLanguage", language]
        }
        if let theme {
            arguments += ["-appTheme", theme]
        }
        return arguments
    }

    @MainActor
    private func captureScreen(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
