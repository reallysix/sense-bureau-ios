import XCTest
@testable import SenseBureau

@MainActor
final class BarometerTests: XCTestCase {
    func testPressureMathAndBaselineSession() {
        XCTAssertEqual(BarometerMath.pressureChange(current: 101.4, reference: 101.3), 0.1, accuracy: 0.0001)

        let provider = FakeBarometerProvider()
        let model = BarometerViewModel(provider: provider)
        model.start()
        provider.send(BarometerReading(pressureKPa: 101.3, relativeAltitudeMeters: 10))
        provider.send(BarometerReading(pressureKPa: 101.4, relativeAltitudeMeters: 12))

        XCTAssertTrue(model.hasReading)
        XCTAssertEqual(model.relativeAltitudeMeters, 2, accuracy: 0.0001)
        XCTAssertEqual(model.pressureChangeKPa, 0.1, accuracy: 0.0001)
        XCTAssertEqual(model.peakAltitudeMeters, 2, accuracy: 0.0001)

        model.setBaseline()
        XCTAssertEqual(model.relativeAltitudeMeters, 0, accuracy: 0.0001)
        XCTAssertEqual(model.pressureChangeKPa, 0, accuracy: 0.0001)
        XCTAssertTrue(model.samples.isEmpty)

        provider.send(BarometerReading(pressureKPa: 101.35, relativeAltitudeMeters: 13))
        XCTAssertEqual(model.relativeAltitudeMeters, 1, accuracy: 0.0001)
        XCTAssertEqual(model.pressureChangeKPa, -0.05, accuracy: 0.0001)
    }

    func testPauseResumePreservesRelativeAltitudeAcrossProviderRestart() {
        let provider = FakeBarometerProvider()
        let model = BarometerViewModel(provider: provider)
        model.start()
        provider.send(BarometerReading(pressureKPa: 101.3, relativeAltitudeMeters: 0))
        provider.send(BarometerReading(pressureKPa: 101.3, relativeAltitudeMeters: 2))

        model.togglePause()
        XCTAssertEqual(model.state, .paused)
        XCTAssertEqual(provider.stopCount, 1)
        model.setBaseline()
        XCTAssertEqual(model.relativeAltitudeMeters, 2, accuracy: 0.0001)

        model.togglePause()
        XCTAssertEqual(provider.startCount, 2)
        provider.send(BarometerReading(pressureKPa: 101.3, relativeAltitudeMeters: 50))
        XCTAssertEqual(model.relativeAltitudeMeters, 2, accuracy: 0.0001)
        provider.send(BarometerReading(pressureKPa: 101.3, relativeAltitudeMeters: 51))
        XCTAssertEqual(model.relativeAltitudeMeters, 3, accuracy: 0.0001)
    }

    func testUnavailableDeniedAndFailureStatesAreDistinct() {
        let unsupported = BarometerViewModel(provider: FakeBarometerProvider(availability: .unsupported))
        let denied = BarometerViewModel(provider: FakeBarometerProvider(availability: .denied))
        unsupported.start()
        denied.start()
        XCTAssertEqual(unsupported.state, .unsupported)
        XCTAssertEqual(denied.state, .denied)

        let provider = FakeBarometerProvider()
        let failed = BarometerViewModel(provider: provider)
        failed.start()
        provider.fail()
        XCTAssertEqual(failed.state, .failed)
        XCTAssertFalse(failed.isProviderRunning)
        XCTAssertEqual(provider.stopCount, 1)
    }
}

@MainActor
private final class FakeBarometerProvider: BarometerProviding {
    let availability: BarometerAvailability
    let isDemo = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var handler: BarometerHandler?

    init(availability: BarometerAvailability = .available) {
        self.availability = availability
    }

    func start(handler: @escaping BarometerHandler) {
        startCount += 1
        self.handler = handler
    }

    func stop() {
        stopCount += 1
    }

    func send(_ reading: BarometerReading) {
        handler?(.success(reading))
    }

    func fail() {
        handler?(.failure(BarometerTestError.failed))
    }
}

private enum BarometerTestError: Error {
    case failed
}
