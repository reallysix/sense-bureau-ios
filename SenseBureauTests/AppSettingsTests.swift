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

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "AppSettingsTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }
}
