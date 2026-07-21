import XCTest
@testable import SenseBureau

@MainActor
final class MotionModuleTests: XCTestCase {
    func testVibrationMathUsesThreeAxesAndComputesRMS() {
        let vector = AccelerationVector(x: 0.003, y: 0.004, z: 0.012)
        XCTAssertEqual(VibrationMath.magnitudeMG(of: vector), 13, accuracy: 0.0001)
        XCTAssertEqual(VibrationMath.rms(of: [3, 4]), sqrt(12.5), accuracy: 0.0001)
        XCTAssertEqual(VibrationMath.baseline(from: []), nil)
    }

    func testVibrationCalibratesMeasuresAndPreservesPause() {
        let provider = FakeVibrationProvider()
        let feedback = MotionFeedbackSpy()
        let model = VibrationViewModel(provider: provider, feedback: feedback)
        model.configureFeedback(soundEnabled: false, hapticsEnabled: true)

        model.start()
        model.start()
        XCTAssertEqual(provider.startCount, 1)

        for _ in 0..<30 {
            provider.send(AccelerationVector(x: 0, y: 0, z: 0))
        }
        XCTAssertEqual(model.state, .active)
        XCTAssertEqual(feedback.calibrationCount, 1)
        XCTAssertEqual(feedback.soundEnabled, false)
        XCTAssertEqual(feedback.hapticsEnabled, true)

        provider.send(AccelerationVector(x: 0.03, y: 0.04, z: 0))
        XCTAssertEqual(model.currentMagnitude, 50, accuracy: 0.001)
        XCTAssertEqual(model.rmsMagnitude, 50, accuracy: 0.001)
        XCTAssertEqual(model.peakMagnitude, 50, accuracy: 0.001)
        XCTAssertEqual(model.samples.count, 1)

        model.togglePause()
        XCTAssertEqual(model.state, .paused)
        XCTAssertFalse(model.isProviderRunning)
        model.calibrate()
        XCTAssertEqual(model.state, .paused)
        model.start()
        XCTAssertEqual(provider.startCount, 1)
        model.togglePause()
        XCTAssertEqual(model.state, .active)
        XCTAssertEqual(provider.startCount, 2)
    }

    func testLevelMathAndZeroReference() {
        let attitude = LevelAttitude(xDegrees: 6, yDegrees: 8)
        XCTAssertEqual(LevelMath.magnitude(of: attitude), 10, accuracy: 0.0001)
        XCTAssertEqual(
            LevelMath.adjusted(attitude, zero: LevelAttitude(xDegrees: 1, yDegrees: 2)),
            LevelAttitude(xDegrees: 5, yDegrees: 6)
        )

        let provider = FakeLevelProvider()
        let feedback = MotionFeedbackSpy()
        let model = LevelViewModel(provider: provider, feedback: feedback)
        model.start()
        provider.send(LevelAttitude(xDegrees: 3, yDegrees: 4))
        XCTAssertEqual(model.tiltMagnitude, 5, accuracy: 0.0001)

        model.zero()
        for _ in 0..<12 {
            provider.send(LevelAttitude(xDegrees: 3, yDegrees: 4))
        }
        XCTAssertEqual(model.state, .active)
        XCTAssertEqual(model.tiltMagnitude, 0, accuracy: 0.0001)
        XCTAssertEqual(feedback.calibrationCount, 1)
        model.togglePause()
        model.zero()
        XCTAssertEqual(model.state, .paused)
    }

    func testUnavailableMotionProvidersUseUnsupportedState() {
        let vibration = VibrationViewModel(
            provider: FakeVibrationProvider(isAvailable: false),
            feedback: MotionFeedbackSpy()
        )
        let level = LevelViewModel(
            provider: FakeLevelProvider(isAvailable: false),
            feedback: MotionFeedbackSpy()
        )

        vibration.start()
        level.start()

        XCTAssertEqual(vibration.state, .unsupported)
        XCTAssertEqual(level.state, .unsupported)

        let failingVibrationProvider = FakeVibrationProvider()
        let failingLevelProvider = FakeLevelProvider()
        let failingVibration = VibrationViewModel(
            provider: failingVibrationProvider,
            feedback: MotionFeedbackSpy()
        )
        let failingLevel = LevelViewModel(
            provider: failingLevelProvider,
            feedback: MotionFeedbackSpy()
        )
        failingVibration.start()
        failingLevel.start()
        failingVibrationProvider.fail()
        failingLevelProvider.fail()

        XCTAssertEqual(failingVibration.state, .failed)
        XCTAssertEqual(failingLevel.state, .failed)
        XCTAssertEqual(failingVibrationProvider.stopCount, 1)
        XCTAssertEqual(failingLevelProvider.stopCount, 1)
    }
}

@MainActor
private final class MotionFeedbackSpy: MeasurementFeedbackProviding {
    private(set) var calibrationCount = 0
    private(set) var soundEnabled: Bool?
    private(set) var hapticsEnabled: Bool?

    func calibrationCompleted(soundEnabled: Bool, hapticsEnabled: Bool) {
        calibrationCount += 1
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
    }

    func thresholdExceeded(soundEnabled: Bool, hapticsEnabled: Bool) {}
}

@MainActor
private final class FakeVibrationProvider: VibrationProviding {
    let isAvailable: Bool
    let isDemo = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var handler: VibrationHandler?

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func start(handler: @escaping VibrationHandler) {
        startCount += 1
        self.handler = handler
    }

    func stop() {
        stopCount += 1
    }

    func send(_ vector: AccelerationVector) {
        handler?(.success(vector))
    }

    func fail() {
        handler?(.failure(MotionProviderTestError.failed))
    }
}

@MainActor
private final class FakeLevelProvider: LevelProviding {
    let isAvailable: Bool
    let isDemo = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var handler: LevelHandler?

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func start(handler: @escaping LevelHandler) {
        startCount += 1
        self.handler = handler
    }

    func stop() {
        stopCount += 1
    }

    func send(_ attitude: LevelAttitude) {
        handler?(.success(attitude))
    }

    func fail() {
        handler?(.failure(MotionProviderTestError.failed))
    }
}

private enum MotionProviderTestError: Error {
    case failed
}
