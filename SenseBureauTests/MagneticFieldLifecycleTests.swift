import XCTest
@testable import SenseBureau

@MainActor
final class MagneticFieldLifecycleTests: XCTestCase {
    func testStartIsIdempotent() {
        let provider = FakeMagnetometerProvider()
        let model = MagneticFieldViewModel(provider: provider)

        model.start()
        model.start()

        XCTAssertEqual(provider.startCount, 1)
        XCTAssertTrue(model.isProviderRunning)
    }

    func testNavigationStopAndRestartPreservesMeasurementSession() {
        let provider = FakeMagnetometerProvider()
        let model = MagneticFieldViewModel(provider: provider)
        model.start()
        completeCalibration(using: provider)
        provider.send(MagneticVector(x: 70, y: 0, z: 0))
        let sampleCount = model.samples.count

        model.stop()

        XCTAssertEqual(provider.stopCount, 1)
        XCTAssertFalse(model.isProviderRunning)
        XCTAssertEqual(model.state, .active)

        model.start()

        XCTAssertEqual(provider.startCount, 2)
        XCTAssertTrue(model.isProviderRunning)
        XCTAssertEqual(model.state, .active)
        XCTAssertEqual(model.samples.count, sampleCount)
    }

    func testPausedSessionDoesNotRestartUntilUserResumes() {
        let provider = FakeMagnetometerProvider()
        let model = MagneticFieldViewModel(provider: provider)
        model.start()
        completeCalibration(using: provider)

        model.togglePause()
        model.start()

        XCTAssertEqual(model.state, .paused)
        XCTAssertEqual(provider.startCount, 1)
        XCTAssertFalse(model.isProviderRunning)

        model.togglePause()

        XCTAssertEqual(model.state, .active)
        XCTAssertEqual(provider.startCount, 2)
        XCTAssertTrue(model.isProviderRunning)
    }

    private func completeCalibration(using provider: FakeMagnetometerProvider) {
        for _ in 0..<30 {
            provider.send(MagneticVector(x: 40, y: 0, z: 0))
        }
    }
}

@MainActor
private final class FakeMagnetometerProvider: MagnetometerProviding {
    let isAvailable = true
    let isDemo = true
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var handler: MagnetometerHandler?

    func start(handler: @escaping MagnetometerHandler) {
        startCount += 1
        self.handler = handler
    }

    func stop() {
        stopCount += 1
    }

    func send(_ vector: MagneticVector) {
        handler?(.success(vector))
    }
}
