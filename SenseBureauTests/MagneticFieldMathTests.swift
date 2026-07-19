import XCTest
@testable import SenseBureau

final class MagneticFieldMathTests: XCTestCase {
    func testMagnitudeUsesAllThreeAxes() {
        let vector = MagneticVector(x: 3, y: 4, z: 12)

        XCTAssertEqual(MagneticFieldMath.magnitude(of: vector), 13, accuracy: 0.0001)
    }

    func testSmoothingKeepsFirstSample() {
        XCTAssertEqual(MagneticFieldMath.smoothed(previous: nil, current: 42), 42)
    }

    func testSmoothingAppliesConfiguredWeight() {
        let result = MagneticFieldMath.smoothed(previous: 40, current: 50, alpha: 0.2)

        XCTAssertEqual(result, 42, accuracy: 0.0001)
    }

    func testBaselineTrimsSingleOutlier() throws {
        let values: [Double] = [50, 50, 51, 49, 50, 50, 50, 51, 49, 500]

        let result = try XCTUnwrap(MagneticFieldMath.baseline(from: values))

        XCTAssertEqual(result, 50.125, accuracy: 0.0001)
    }

    func testBaselineRejectsEmptyInput() {
        XCTAssertNil(MagneticFieldMath.baseline(from: []))
    }
}
