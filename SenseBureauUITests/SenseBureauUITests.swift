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
        XCTAssertTrue(app.buttons["tool.vibration"].isEnabled)
        XCTAssertTrue(app.buttons["tool.level"].isEnabled)
        XCTAssertTrue(app.buttons["tool.barometer"].isEnabled)
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

    @MainActor
    func testMotionModulesMeasureSaveAndPreservePause() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "en", theme: "techSignal")
        app.launch()

        app.buttons["tool.vibration"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["vibration.current"].waitForExistence(timeout: 4))
        let vibrationPause = app.buttons["vibration.pause"]
        let vibrationReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: vibrationPause
        )
        XCTAssertEqual(XCTWaiter.wait(for: [vibrationReady], timeout: 4), .completed)
        vibrationPause.tap()
        XCTAssertEqual(vibrationPause.label, "RESUME")
        let vibrationSave = app.buttons["vibration.save"]
        XCTAssertTrue(vibrationSave.isEnabled)
        vibrationSave.tap()
        XCTAssertEqual(app.staticTexts["sensor.status"].label, "SAVED")
        XCTAssertEqual(vibrationSave.label, "SAVE")
        XCTAssertFalse(app.buttons["vibration.calibrate"].isEnabled)
        captureScreen(named: "stage3b-vibration-tech-en-paused")

        app.buttons["nav.level"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["level.tilt"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["level.axis.x"].exists)
        app.buttons["level.zero"].tap()
        let levelPause = app.buttons["level.pause"]
        let levelReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: levelPause
        )
        XCTAssertEqual(XCTWaiter.wait(for: [levelReady], timeout: 4), .completed)
        captureScreen(named: "stage3b-level-tech-en-zeroed")

        app.buttons["nav.vibration"].tap()
        XCTAssertTrue(vibrationPause.waitForExistence(timeout: 3))
        XCTAssertEqual(vibrationPause.label, "RESUME")
    }

    @MainActor
    func testMotionModulesRenderInChineseCartoonTheme() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "zh-Hans", theme: "cartoonExplorer")
        app.launch()

        app.buttons["tool.vibration"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["vibration.current"].waitForExistence(timeout: 4))
        captureScreen(named: "stage3b-vibration-cartoon-zh-Hans")

        app.buttons["nav.level"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["level.tilt"].waitForExistence(timeout: 4))
        captureScreen(named: "stage3b-level-cartoon-zh-Hans")
    }

    @MainActor
    func testBarometerSavesAndDisplaysRecentRecords() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "en", theme: "techSignal")
        app.launch()

        openBarometer(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["barometer.pressure"].waitForExistence(timeout: 4))
        let pause = app.buttons["barometer.pause"]
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: pause
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 4), .completed)
        XCTAssertTrue(app.buttons["barometer.baseline"].isEnabled)
        app.buttons["barometer.baseline"].tap()
        pause.tap()
        XCTAssertEqual(pause.label, "RESUME")
        app.buttons["barometer.save"].tap()
        XCTAssertEqual(app.staticTexts["sensor.status"].label, "SAVED")
        captureScreen(named: "stage3c-barometer-tech-en-paused")

        app.buttons["nav.lab"].tap()
        let viewAll = app.buttons["VIEW ALL RECORDS"]
        scrollUp(in: app, until: viewAll)
        XCTAssertTrue(viewAll.isHittable)
        viewAll.tap()
        XCTAssertTrue(app.staticTexts["MEASUREMENT RECORDS"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Pressure & Height"))
            .firstMatch.exists)
        captureScreen(named: "stage3c-records-tech-en-populated")
        app.buttons["Close records"].tap()
    }

    @MainActor
    func testPressureUnitAndRecordClearing() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "zh-Hans", theme: "cartoonExplorer")
        app.launch()
        openBarometer(in: app)

        let save = app.buttons["barometer.save"]
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: save
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 4), .completed)
        save.tap()
        app.buttons["nav.settings"].tap()

        let kPa = app.buttons["settings.pressureUnit.kilopascals"]
        scrollUp(in: app, until: kPa)
        XCTAssertTrue(kPa.isHittable)
        kPa.tap()
        XCTAssertEqual(kPa.value as? String, "已选择")

        let clear = app.buttons["settings.data.clear"]
        scrollUp(in: app, until: clear)
        XCTAssertTrue(clear.isEnabled)
        captureScreen(named: "stage3c-settings-cartoon-zh-Hans-data")
        clear.tap()
        XCTAssertTrue(app.alerts["清除全部记录？"].waitForExistence(timeout: 2))
        captureScreen(named: "stage3c-settings-cartoon-zh-Hans-delete-confirmation")
        app.alerts["清除全部记录？"].buttons["全部删除"].tap()
        let cleared = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == false"),
            object: clear
        )
        XCTAssertEqual(XCTWaiter.wait(for: [cleared], timeout: 3), .completed)

        app.buttons["nav.lab"].tap()
        let empty = app.descendants(matching: .any)["暂无测量记录"]
        scrollUp(in: app, until: empty)
        XCTAssertTrue(empty.exists)
    }

    @MainActor
    func testBarometerUnavailableAndDeniedStates() throws {
        let app = XCUIApplication()
        app.launchArguments = standardArguments(language: "en", theme: "techSignal")
            + ["-barometerUnsupported"]
        app.launch()
        openBarometer(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["sensor.stateNotice"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["sensor.status"].label, "NO SENSOR")
        captureScreen(named: "stage3c-barometer-tech-en-unsupported")

        app.terminate()
        app.launchArguments = standardArguments(language: "en", theme: "techSignal")
            + ["-barometerDenied"]
        app.launch()
        openBarometer(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["sensor.stateNotice"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["sensor.status"].label, "NO ACCESS")
        captureScreen(named: "stage3c-barometer-tech-en-denied")
    }

    private func standardArguments(language: String? = nil, theme: String? = nil) -> [String] {
        var arguments = [
            "-hasSeenMagneticGuide", "YES",
            "-appSoundEnabled", "NO",
            "-appPressureUnit", "hectopascals",
            "-uiTestResetRecords",
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
    private func scrollUp(in app: XCUIApplication, until element: XCUIElement) {
        for _ in 0..<8 where !element.isHittable {
            app.swipeUp()
        }
    }

    @MainActor
    private func openBarometer(in app: XCUIApplication) {
        let button = app.buttons["tool.barometer"]
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        app.swipeUp()
        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    @MainActor
    private func captureScreen(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
