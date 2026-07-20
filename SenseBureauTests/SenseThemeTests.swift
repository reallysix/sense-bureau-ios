import XCTest
@testable import SenseBureau

final class SenseThemeTests: XCTestCase {
    func testEveryThemeProvidesTheCompleteSemanticColorContract() {
        let expectedTokens = Set([
            "canvasPrimary", "surfacePrimary", "surfaceRaised", "surfaceData",
            "signalPrimary", "signalPressed", "signalBright", "textPrimary",
            "textSecondary", "textOnSignal", "textOnData", "strokeSubtle",
            "navigationSurface", "navigationText", "critical",
        ])

        for theme in AppTheme.allCases {
            let definition = theme.definition
            let actualTokens = Set(Mirror(reflecting: definition.colors).children.compactMap(\.label))

            XCTAssertEqual(definition.id, theme)
            XCTAssertEqual(actualTokens, expectedTokens, "Incomplete semantic colors for \(theme)")
        }
    }

    func testThemeRadiiStayWithinDesignSystemBounds() {
        for theme in AppTheme.allCases {
            let radius = theme.definition.radius
            XCTAssertGreaterThan(radius.small, 0)
            XCTAssertGreaterThanOrEqual(radius.medium, radius.small)
            XCTAssertGreaterThanOrEqual(radius.large, radius.medium)
            XCTAssertEqual(radius.navigation, 22)
            XCTAssertLessThanOrEqual(radius.large, 22)
        }
    }
}
