import XCTest
@testable import SenseBureau

final class AppSettingsTests: XCTestCase {
    @MainActor
    func testThemeDefaultsToTechSignal() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(AppSettings(defaults: defaults).theme, .techSignal)
    }

    @MainActor
    func testThemeSelectionPersists() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.theme = .cartoonExplorer

        XCTAssertEqual(AppSettings(defaults: defaults).theme, .cartoonExplorer)
    }

    @MainActor
    func testMeasurementPreferencesHaveSafeDefaults() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        XCTAssertTrue(settings.soundEnabled)
        XCTAssertTrue(settings.hapticsEnabled)
        XCTAssertEqual(settings.alertThreshold, 30)
        XCTAssertFalse(settings.hasSeenMagneticGuide)
    }

    @MainActor
    func testMeasurementPreferencesPersist() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.soundEnabled = false
        settings.hapticsEnabled = false
        settings.alertThreshold = 55
        settings.hasSeenMagneticGuide = true

        let restored = AppSettings(defaults: defaults)
        XCTAssertFalse(restored.soundEnabled)
        XCTAssertFalse(restored.hapticsEnabled)
        XCTAssertEqual(restored.alertThreshold, 55)
        XCTAssertTrue(restored.hasSeenMagneticGuide)
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "AppSettingsTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }
}
