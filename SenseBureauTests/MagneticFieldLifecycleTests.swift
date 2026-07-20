import XCTest
@testable import SenseBureau

@MainActor
final class MagneticFieldLifecycleTests: XCTestCase {
    func testStartIsIdempotent() {
        let provider = FakeMagnetometerProvider()
        let model = MagneticFieldViewModel(
            provider: provider,
            feedback: FakeMeasurementFeedback()
        )

        model.start()
        model.start()

        XCTAssertEqual(provider.startCount, 1)
        XCTAssertTrue(model.isProviderRunning)
    }

    func testNavigationStopAndRestartPreservesMeasurementSession() {
        let provider = FakeMagnetometerProvider()
        let model = MagneticFieldViewModel(
            provider: provider,
            feedback: FakeMeasurementFeedback()
        )
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
        let model = MagneticFieldViewModel(
            provider: provider,
            feedback: FakeMeasurementFeedback()
        )
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

    func testConfiguredFeedbackAndRawAxesAreUsed() {
        let provider = FakeMagnetometerProvider()
        let feedback = FakeMeasurementFeedback()
        let model = MagneticFieldViewModel(provider: provider, feedback: feedback)
        model.configureFeedback(
            soundEnabled: false,
            hapticsEnabled: true,
            alertThreshold: 5
        )

        model.start()
        completeCalibration(using: provider)

        XCTAssertEqual(model.alertThreshold, 10)
        XCTAssertEqual(feedback.calibrationCount, 1)
        XCTAssertEqual(feedback.calibrationSoundEnabled, false)
        XCTAssertEqual(feedback.calibrationHapticsEnabled, true)

        let vector = MagneticVector(x: 100, y: -20, z: 8)
        provider.send(vector)

        XCTAssertEqual(model.latestVector, vector)
        XCTAssertEqual(feedback.thresholdCount, 1)
        XCTAssertEqual(feedback.thresholdSoundEnabled, false)
        XCTAssertEqual(feedback.thresholdHapticsEnabled, true)
    }

    func testAlertThresholdIsClampedToSupportedRange() {
        let model = MagneticFieldViewModel(
            provider: FakeMagnetometerProvider(),
            feedback: FakeMeasurementFeedback()
        )

        model.configureFeedback(soundEnabled: true, hapticsEnabled: true, alertThreshold: 120)
        XCTAssertEqual(model.alertThreshold, 100)

        model.configureFeedback(soundEnabled: true, hapticsEnabled: true, alertThreshold: -5)
        XCTAssertEqual(model.alertThreshold, 10)
    }

    private func completeCalibration(using provider: FakeMagnetometerProvider) {
        for _ in 0..<30 {
            provider.send(MagneticVector(x: 40, y: 0, z: 0))
        }
    }
}

@MainActor
private final class FakeMeasurementFeedback: MeasurementFeedbackProviding {
    private(set) var calibrationCount = 0
    private(set) var calibrationSoundEnabled: Bool?
    private(set) var calibrationHapticsEnabled: Bool?
    private(set) var thresholdCount = 0
    private(set) var thresholdSoundEnabled: Bool?
    private(set) var thresholdHapticsEnabled: Bool?

    func calibrationCompleted(soundEnabled: Bool, hapticsEnabled: Bool) {
        calibrationCount += 1
        calibrationSoundEnabled = soundEnabled
        calibrationHapticsEnabled = hapticsEnabled
    }

    func thresholdExceeded(soundEnabled: Bool, hapticsEnabled: Bool) {
        thresholdCount += 1
        thresholdSoundEnabled = soundEnabled
        thresholdHapticsEnabled = hapticsEnabled
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
